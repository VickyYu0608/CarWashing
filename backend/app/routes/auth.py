from __future__ import annotations

import secrets
import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
from fastapi import APIRouter, Depends, HTTPException
from app.auth_deps import get_current_account, get_token_payload
from jose import jwt
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.account_json import account_to_json, referred_user_id_list, set_referred_user_ids
from app.config import get_settings
from app.database import AccountRecord, StoreRecord, get_db
from app.services.email_service import send_verification_email
from app.services.verification_service import issue_code, verify_code

router = APIRouter(prefix="/api/auth", tags=["auth"])

DEMO_USERS = {
    "user": {"password": "123456", "role": "user", "display_name": "Demo user"},
    "shop": {"password": "123456", "role": "shop", "display_name": "Demo shop"},
    "admin": {"password": "123456", "role": "admin", "display_name": "Admin"},
}

class LoginRequest(BaseModel):
    username: str
    password: str


class SendEmailCodeRequest(BaseModel):
    email: EmailStr
    purpose: str = Field(default="register_user", pattern="^(register_user|register_shop)$")


class RegisterUserRequest(BaseModel):
    country_code: str = "+86"
    phone: str
    email: EmailStr
    verification_code: str
    password: str
    display_name: str
    referral_code: str = ""


class RegisterShopRequest(BaseModel):
    country_code: str = "+852"
    phone: str
    email: EmailStr
    verification_code: str
    password: str
    store_name: str
    address: str
    latitude: float
    longitude: float
    license_files: list[str] = Field(default_factory=list)
    service_types: list[str] = Field(default_factory=list)


def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def _verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))


def _create_token(username: str, role: str) -> str:
    settings = get_settings()
    return jwt.encode(
        {
            "sub": username,
            "role": role,
            "exp": datetime.now(timezone.utc) + timedelta(days=7),
        },
        settings.jwt_secret,
        algorithm="HS256",
    )


def _account_to_json(account: AccountRecord) -> dict:
    return account_to_json(account)


class RedeemReferralRequest(BaseModel):
    code: str


@router.post("/email/send")
def send_email_code(body: SendEmailCodeRequest, db: Session = Depends(get_db)):
    settings = get_settings()
    email = body.email.strip().lower()
    purpose = body.purpose

    code = issue_code(
        db,
        email=email,
        purpose=purpose,
        ttl_seconds=settings.verification_code_ttl_seconds,
    )

    message = "Verification code sent to your email"
    dev_code: str | None = None
    email_sent = False

    try:
        if settings.email_demo_mode and not settings.email_ready:
            dev_code = code
            message = "Demo mode: email provider not configured (see backend/.env)"
        else:
            send_verification_email(to_email=email, code=code, purpose=purpose)
            email_sent = True
    except Exception as exc:  # noqa: BLE001
        if settings.email_demo_mode:
            dev_code = code
            message = f"Demo mode: could not send email ({exc})"
        else:
            raise HTTPException(status_code=502, detail=str(exc)) from exc

    payload: dict = {"message": message, "email": email, "email_sent": email_sent}
    # Never expose the code when email was delivered — user must read their inbox.
    if dev_code is not None and not email_sent:
        payload["dev_code"] = dev_code
    return payload


@router.post("/register/user")
def register_user(body: RegisterUserRequest, db: Session = Depends(get_db)):
    email = body.email.strip().lower()
    if not verify_code(
        db, email=email, code=body.verification_code.strip(), purpose="register_user"
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")

    username = f"{body.country_code.strip()}{body.phone.strip()}"
    if db.scalar(select(AccountRecord).where(AccountRecord.username == username)):
        raise HTTPException(status_code=409, detail="Phone number already registered")
    if db.scalar(select(AccountRecord).where(AccountRecord.email == email)):
        raise HTTPException(status_code=409, detail="Email already registered")

    account = AccountRecord(
        id=f"user-{uuid.uuid4().hex[:12]}",
        username=username,
        password_hash=_hash_password(body.password),
        email=email,
        country_code=body.country_code.strip(),
        phone=body.phone.strip(),
        role="user",
        display_name=body.display_name.strip(),
        approval_status="approved",
        share_code=secrets.token_hex(4).upper(),
    )
    db.add(account)
    db.flush()
    if body.referral_code.strip():
        try:
            _apply_referral(db, account, body.referral_code)
        except HTTPException:
            pass
    db.commit()
    db.refresh(account)

    token = _create_token(account.username, account.role)
    return {**_account_to_json(account), "access_token": token, "token_type": "bearer"}


@router.post("/register/shop")
def register_shop(body: RegisterShopRequest, db: Session = Depends(get_db)):
    email = body.email.strip().lower()
    if not body.license_files:
        raise HTTPException(status_code=400, detail="Upload at least one license file")
    if not verify_code(
        db, email=email, code=body.verification_code.strip(), purpose="register_shop"
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")

    username = f"{body.country_code.strip()}{body.phone.strip()}"
    if db.scalar(select(AccountRecord).where(AccountRecord.username == username)):
        raise HTTPException(status_code=409, detail="Phone number already registered")
    if db.scalar(select(AccountRecord).where(AccountRecord.email == email)):
        raise HTTPException(status_code=409, detail="Email already registered")

    account_id = f"shop-{uuid.uuid4().hex[:12]}"
    account = AccountRecord(
        id=account_id,
        username=username,
        password_hash=_hash_password(body.password),
        email=email,
        country_code=body.country_code.strip(),
        phone=body.phone.strip(),
        role="shop",
        display_name=body.store_name.strip(),
        approval_status="pending",
        shop_address=body.address.strip(),
        shop_latitude=body.latitude,
        shop_longitude=body.longitude,
    )
    db.add(account)

    store = StoreRecord(
        id=f"store-{uuid.uuid4().hex[:12]}",
        owner_account_id=account_id,
        name=body.store_name.strip(),
        address=body.address.strip(),
        latitude=body.latitude,
        longitude=body.longitude,
        approval_status="pending",
        service_types=",".join(body.service_types),
        license_files=",".join(body.license_files),
    )
    db.add(store)
    db.commit()
    db.refresh(account)

    token = _create_token(account.username, account.role)
    return {**_account_to_json(account), "access_token": token, "token_type": "bearer"}


@router.post("/login")
def login(body: LoginRequest, db: Session = Depends(get_db)):
    username = body.username.strip()

    account = db.scalar(select(AccountRecord).where(AccountRecord.username == username))
    if account is not None:
        if not _verify_password(body.password, account.password_hash):
            raise HTTPException(status_code=401, detail="Account or password does not match")
        token = _create_token(account.username, account.role)
        return {"access_token": token, "token_type": "bearer"}

    demo = DEMO_USERS.get(username)
    if demo is None or demo["password"] != body.password:
        raise HTTPException(status_code=401, detail="Account or password does not match")

    token = _create_token(username, demo["role"])
    return {"access_token": token, "token_type": "bearer"}


def _find_account_by_share_code(db: Session, code: str) -> AccountRecord | None:
    normalized = code.strip().upper()
    if not normalized:
        return None
    return db.scalar(
        select(AccountRecord).where(AccountRecord.share_code == normalized)
    )


def _apply_referral(
    db: Session, redeemer: AccountRecord, code: str
) -> AccountRecord:
    if redeemer.referred_by_user_id:
        raise HTTPException(status_code=400, detail="Referral code already used")
    referrer = _find_account_by_share_code(db, code)
    if referrer is None:
        raise HTTPException(status_code=400, detail="Invalid referral code")
    if referrer.id == redeemer.id:
        raise HTTPException(status_code=400, detail="Cannot use your own referral code")

    redeemer.referred_by_user_id = referrer.id
    redeemer.free_wash_credits += 1
    referrer.free_wash_credits += 1
    referred = referred_user_id_list(referrer)
    if redeemer.id not in referred:
        referred.append(redeemer.id)
    set_referred_user_ids(referrer, referred)
    db.flush()
    return referrer


@router.post("/referral/redeem")
def redeem_referral(
    body: RedeemReferralRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
):
    if account.role != "user":
        raise HTTPException(status_code=400, detail="Only users can redeem referral codes")
    referrer = _apply_referral(db, account, body.code)
    db.commit()
    db.refresh(account)
    db.refresh(referrer)
    payload = _account_to_json(account)
    payload["referrer_free_wash_credits"] = referrer.free_wash_credits
    payload["referrer_id"] = referrer.id
    return payload


@router.get("/me")
def me(
    payload: dict = Depends(get_token_payload),
    db: Session = Depends(get_db),
):
    username = payload.get("sub")
    if not username:
        raise HTTPException(status_code=401, detail="Invalid token subject")

    account = db.scalar(
        select(AccountRecord).where(AccountRecord.username == username)
    )
    if account is not None:
        return _account_to_json(account)

    demo = DEMO_USERS.get(username)
    if demo is None:
        raise HTTPException(status_code=404, detail="Account not found")

    return {
        "id": f"demo-{username}",
        "username": username,
        "email": f"{username}@demo.local",
        "country_code": "+86",
        "phone": "",
        "role": demo["role"],
        "display_name": demo["display_name"],
        "approval_status": "approved",
        "shop_address": "",
        "shop_latitude": None,
        "shop_longitude": None,
        "share_code": "",
    }
