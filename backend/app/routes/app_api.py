from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth_deps import get_current_account
from app.database import AccountRecord, StoreRecord, get_db
from app.demo_catalog import BUNDLE_PLANS, store_to_json
from app.seed_data import ensure_store_for_shop_account

router = APIRouter(tags=["app"])


@router.get("/api/stores")
def list_stores(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    rows = db.scalars(
        select(StoreRecord)
        .where(StoreRecord.approval_status == "approved")
        .order_by(StoreRecord.created_at.desc())
    ).all()
    return [store_to_json(store) for store in rows]


@router.get("/api/stores/mine")
def list_my_stores(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    ensure_store_for_shop_account(db, account)
    rows = db.scalars(
        select(StoreRecord)
        .where(StoreRecord.owner_account_id == account.id)
        .order_by(StoreRecord.created_at.desc())
    ).all()
    return [store_to_json(store) for store in rows]


@router.get("/api/orders")
def list_orders(
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return []


@router.get("/api/reservations")
def list_reservations(
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return []


@router.get("/api/vehicles")
def list_vehicles(
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return []


@router.get("/api/addresses")
def list_addresses(
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return []


@router.get("/api/wallet")
def get_wallet(
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    return {"balance": 0.0, "transactions": []}


@router.get("/api/bundles")
def list_bundles(
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return BUNDLE_PLANS


@router.get("/api/reviews")
def list_reviews(
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return []
