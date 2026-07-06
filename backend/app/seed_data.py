from __future__ import annotations

import uuid

import bcrypt
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import AccountRecord, StoreRecord


def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def _ensure_demo_account(
    db: Session,
    *,
    id: str,
    username: str,
    password: str,
    email: str,
    country_code: str,
    phone: str,
    role: str,
    display_name: str,
    share_code: str = "",
    shop_address: str = "",
    shop_latitude: float | None = None,
    shop_longitude: float | None = None,
) -> AccountRecord:
    account = db.scalar(
        select(AccountRecord).where(AccountRecord.username == username)
    )
    if account is not None:
        return account
    account = AccountRecord(
        id=id,
        username=username,
        password_hash=_hash_password(password),
        email=email,
        country_code=country_code,
        phone=phone,
        role=role,
        display_name=display_name,
        approval_status="approved",
        shop_address=shop_address,
        shop_latitude=shop_latitude,
        shop_longitude=shop_longitude,
        share_code=share_code,
    )
    db.add(account)
    db.flush()
    return account


def ensure_demo_data(db: Session) -> None:
    shop = _ensure_demo_account(
        db,
        id="shop-demo",
        username="shop",
        password="123456",
        email="shop-demo@wash.local",
        country_code="+852",
        phone="13800000002",
        role="shop",
        display_name="蓝鲸运营",
        shop_address="香港港岛中西区干诺道中 88 号",
        shop_latitude=22.2819,
        shop_longitude=114.1589,
        share_code="SHOPDEMO1",
    )
    _ensure_demo_account(
        db,
        id="user-demo",
        username="user",
        password="123456",
        email="user-demo@wash.local",
        country_code="+86",
        phone="13800000001",
        role="user",
        display_name="演示用户",
        share_code="DEMOCW01",
    )
    _ensure_demo_account(
        db,
        id="admin-demo",
        username="admin",
        password="123456",
        email="admin-demo@wash.local",
        country_code="+86",
        phone="13800000000",
        role="admin",
        display_name="平台管理员",
    )

    store_count = db.scalar(select(func.count()).select_from(StoreRecord)) or 0
    if store_count > 0:
        db.commit()
        return

    demo_stores = [
        StoreRecord(
            id="store-1",
            owner_account_id=shop.id,
            name="蓝鲸自助洗车 中环店",
            address="香港港岛中西区干诺道中 88 号",
            latitude=22.2819,
            longitude=114.1589,
            approval_status="approved",
            service_types="self_service",
        ),
        StoreRecord(
            id="store-2",
            owner_account_id=shop.id,
            name="净驰洗车 观塘店",
            address="香港九龙观塘区成业街 21 号",
            latitude=22.3114,
            longitude=114.2260,
            approval_status="approved",
            service_types="self_service,manual",
        ),
        StoreRecord(
            id="store-3",
            owner_account_id=shop.id,
            name="驿站人工洗车 沙田店",
            address="香港新界沙田区沙田正街 3 号",
            latitude=22.3875,
            longitude=114.1953,
            approval_status="approved",
            service_types="manual",
        ),
    ]
    db.add_all(demo_stores)
    db.commit()


def ensure_store_for_shop_account(db: Session, account: AccountRecord) -> None:
    if account.role != "shop":
        return
    existing = db.scalar(
        select(StoreRecord).where(StoreRecord.owner_account_id == account.id)
    )
    if existing is not None:
        return
    store = StoreRecord(
        id=f"store-{uuid.uuid4().hex[:12]}",
        owner_account_id=account.id,
        name=account.display_name or "我的洗车店",
        address=account.shop_address or "",
        latitude=account.shop_latitude or 22.3,
        longitude=account.shop_longitude or 114.17,
        approval_status=account.approval_status,
        service_types="self_service",
    )
    db.add(store)
    db.commit()
