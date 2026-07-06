from __future__ import annotations

import uuid

import bcrypt
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import AccountRecord, StoreRecord


def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def ensure_demo_data(db: Session) -> None:
    shop = db.scalar(
        select(AccountRecord).where(AccountRecord.username == "shop")
    )
    if shop is None:
        shop = AccountRecord(
            id="shop-demo",
            username="shop",
            password_hash=_hash_password("123456"),
            email="shop-demo@wash.local",
            country_code="+852",
            phone="13800000002",
            role="shop",
            display_name="蓝鲸运营",
            approval_status="approved",
            shop_address="香港港岛中西区干诺道中 88 号",
            shop_latitude=22.2819,
            shop_longitude=114.1589,
            share_code="SHOPDEMO1",
        )
        db.add(shop)
        db.flush()

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
