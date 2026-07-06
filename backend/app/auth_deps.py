from __future__ import annotations

from fastapi import Depends, Header, HTTPException
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database import AccountRecord, get_db


def _decode_token(authorization: str | None) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.removeprefix("Bearer ").strip()
    settings = get_settings()
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired token") from exc


def get_token_payload(authorization: str | None = Header(default=None)) -> dict:
    return _decode_token(authorization)


def get_current_account(
    payload: dict = Depends(get_token_payload),
    db: Session = Depends(get_db),
) -> AccountRecord:
    username = payload.get("sub")
    if not username:
        raise HTTPException(status_code=401, detail="Invalid token subject")
    account = db.scalar(
        select(AccountRecord).where(AccountRecord.username == username)
    )
    if account is None:
        raise HTTPException(status_code=404, detail="Account not found")
    return account
