from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth_deps import get_current_account
from app.bundle_store import list_bundle_plans, update_bundle_plan as persist_bundle_plan
from app.database import (
    AccountRecord,
    AddressRecord,
    OrderRecord,
    ReservationRecord,
    StoreRecord,
    VehicleRecord,
    WalletBalanceRecord,
    WalletTransactionRecord,
    get_db,
)
from app.demo_catalog import store_to_json
from app.package_store import update_package
from app.seed_data import ensure_store_for_shop_account
from app.serializers import (
    address_to_json,
    order_to_json,
    reservation_to_json,
    vehicle_to_json,
    wallet_to_json,
)

router = APIRouter(tags=["app"])


class PurchaseBundleRequest(BaseModel):
    plan_id: str


class UpdatePackageRequest(BaseModel):
    price: float | None = Field(default=None, ge=0)
    minutes: int | None = Field(default=None, gt=0)
    name: str | None = None


class UpdateBundlePlanRequest(BaseModel):
    price: float | None = Field(default=None, ge=0)
    wash_count: int | None = Field(default=None, gt=0)
    name: str | None = None


def _bundle_plan(db: Session, plan_id: str) -> dict:
    for plan in list_bundle_plans(db):
        if plan["id"] == plan_id:
            return plan
    raise HTTPException(status_code=404, detail="Package not found")


def _store_for_owner(db: Session, store_id: str, account: AccountRecord) -> StoreRecord:
    store = db.scalar(select(StoreRecord).where(StoreRecord.id == store_id))
    if store is None:
        raise HTTPException(status_code=404, detail="Store not found")
    if store.owner_account_id != account.id and account.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed to edit this store")
    return store


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
    return [store_to_json(store, db) for store in rows]


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
    return [store_to_json(store, db) for store in rows]


@router.get("/api/orders")
def list_orders(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    if account.role == "user":
        rows = db.scalars(
            select(OrderRecord)
            .where(OrderRecord.user_account_id == account.id)
            .order_by(OrderRecord.created_at.desc())
        ).all()
    elif account.role == "shop":
        store_ids = db.scalars(
            select(StoreRecord.id).where(StoreRecord.owner_account_id == account.id)
        ).all()
        if not store_ids:
            return []
        rows = db.scalars(
            select(OrderRecord)
            .where(OrderRecord.store_id.in_(store_ids))
            .order_by(OrderRecord.created_at.desc())
        ).all()
    else:
        rows = db.scalars(select(OrderRecord).order_by(OrderRecord.created_at.desc())).all()
    return [order_to_json(order) for order in rows]


@router.get("/api/reservations")
def list_reservations(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    if account.role == "user":
        rows = db.scalars(
            select(ReservationRecord)
            .where(ReservationRecord.user_account_id == account.id)
            .order_by(ReservationRecord.created_at.desc())
        ).all()
    elif account.role == "shop":
        store_ids = db.scalars(
            select(StoreRecord.id).where(StoreRecord.owner_account_id == account.id)
        ).all()
        if not store_ids:
            return []
        rows = db.scalars(
            select(ReservationRecord)
            .where(ReservationRecord.store_id.in_(store_ids))
            .order_by(ReservationRecord.created_at.desc())
        ).all()
    else:
        rows = db.scalars(
            select(ReservationRecord).order_by(ReservationRecord.created_at.desc())
        ).all()
    return [reservation_to_json(item) for item in rows]


@router.get("/api/vehicles")
def list_vehicles(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    rows = db.scalars(
        select(VehicleRecord)
        .where(VehicleRecord.user_account_id == account.id)
        .order_by(VehicleRecord.plate.asc())
    ).all()
    return [vehicle_to_json(item) for item in rows]


@router.get("/api/addresses")
def list_addresses(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    rows = db.scalars(
        select(AddressRecord)
        .where(AddressRecord.user_account_id == account.id)
        .order_by(AddressRecord.label.asc())
    ).all()
    return [address_to_json(item) for item in rows]


@router.get("/api/wallet")
def get_wallet(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    balance = db.get(WalletBalanceRecord, account.id)
    transactions = db.scalars(
        select(WalletTransactionRecord)
        .where(WalletTransactionRecord.account_id == account.id)
        .order_by(WalletTransactionRecord.created_at.desc())
    ).all()
    return wallet_to_json(balance, list(transactions))


@router.get("/api/bundles")
def list_bundles(
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return list_bundle_plans(db)


@router.patch("/api/bundles/{plan_id}")
def patch_bundle_plan(
    plan_id: str,
    body: UpdateBundlePlanRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    if account.role not in {"shop", "admin"}:
        raise HTTPException(status_code=403, detail="Shop or admin access required")
    try:
        return persist_bundle_plan(
            db,
            plan_id=plan_id,
            price=body.price,
            wash_count=body.wash_count,
            name=body.name,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/api/bundles/purchase")
def purchase_bundle(
    body: PurchaseBundleRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    if account.role != "user":
        raise HTTPException(status_code=400, detail="Only users can purchase bundles")
    plan = _bundle_plan(db, body.plan_id.strip())
    wash_count = int(plan["wash_count"])
    account.prepaid_wash_credits += wash_count
    db.commit()
    db.refresh(account)
    return {
        "plan_id": plan["id"],
        "wash_count_added": wash_count,
        "prepaid_wash_credits": account.prepaid_wash_credits,
    }


@router.patch("/api/stores/{store_id}/packages/{package_id}")
def patch_store_package(
    store_id: str,
    package_id: str,
    body: UpdatePackageRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    if account.role not in {"shop", "admin"}:
        raise HTTPException(status_code=403, detail="Shop access required")
    store = _store_for_owner(db, store_id, account)
    update_package(
        db,
        store_id=store_id,
        package_id=package_id,
        price=body.price,
        minutes=body.minutes,
        name=body.name,
    )
    return store_to_json(store, db)


@router.get("/api/reviews")
def list_reviews(
    account: AccountRecord = Depends(get_current_account),
) -> list[dict]:
    return []
