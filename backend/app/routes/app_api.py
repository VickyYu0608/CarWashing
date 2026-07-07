from __future__ import annotations

import uuid
from datetime import datetime, timezone

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
from app.demo_catalog import _devices_for_store, _packages_for_store, store_to_json
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


class CreateOrderRequest(BaseModel):
    store_id: str
    device_id: str
    package_id: str
    amount: float = Field(ge=0)
    used_free_wash_credit: bool = False
    used_prepaid_wash_credit: bool = False


class UpdateOrderRequest(BaseModel):
    status: str | None = None
    payment_transaction_id: str | None = None
    payment_method: str | None = None
    provider_reference: str | None = None


class CreateReservationRequest(BaseModel):
    store_id: str
    service_type: str = "selfService"
    user_latitude: float
    user_longitude: float
    distance_km: float = Field(ge=0)
    eta_minutes: int = Field(ge=0)
    arrival_time: datetime
    contact_phone: str
    note: str = ""


class UpdateReservationRequest(BaseModel):
    status: str | None = None


class CreateVehicleRequest(BaseModel):
    plate: str
    model: str
    color: str = ""


class CreateAddressRequest(BaseModel):
    label: str
    address: str
    latitude: float | None = None
    longitude: float | None = None


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
def list_bundles(db: Session = Depends(get_db)) -> list[dict]:
    """Public pricing list so user and shop apps stay in sync."""
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


def _order_for_account(
    db: Session, order_id: str, account: AccountRecord
) -> OrderRecord:
    order = db.get(OrderRecord, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    if account.role == "user" and order.user_account_id != account.id:
        raise HTTPException(status_code=403, detail="Not allowed to access this order")
    if account.role == "shop":
        store = db.get(StoreRecord, order.store_id)
        if store is None or store.owner_account_id != account.id:
            raise HTTPException(status_code=403, detail="Not allowed to access this order")
    return order


@router.post("/api/orders")
def create_order(
    body: CreateOrderRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    if account.role != "user":
        raise HTTPException(status_code=400, detail="Only users can create orders")

    store = db.get(StoreRecord, body.store_id.strip())
    if store is None or store.approval_status != "approved":
        raise HTTPException(status_code=404, detail="Store not found")

    devices = _devices_for_store(store, db)
    device = next(
        (item for item in devices if item["id"] == body.device_id.strip()),
        None,
    )
    if device is None:
        raise HTTPException(status_code=404, detail="Device not found")
    if device["status"] != "idle":
        raise HTTPException(status_code=400, detail="Device unavailable")

    packages = _packages_for_store(store, db)
    package = next(
        (item for item in packages if item["id"] == body.package_id.strip()),
        None,
    )
    if package is None:
        raise HTTPException(status_code=404, detail="Package not found")

    if body.used_free_wash_credit and body.used_prepaid_wash_credit:
        raise HTTPException(status_code=400, detail="Cannot use both credits")
    if body.used_free_wash_credit:
        if account.free_wash_credits <= 0:
            raise HTTPException(status_code=400, detail="No free wash credits")
        account.free_wash_credits -= 1
    if body.used_prepaid_wash_credit:
        if account.prepaid_wash_credits <= 0:
            raise HTTPException(status_code=400, detail="No prepaid wash credits")
        account.prepaid_wash_credits -= 1

    use_credit = body.used_free_wash_credit or body.used_prepaid_wash_credit
    amount = 0.0 if use_credit else float(body.amount)
    now = datetime.now(timezone.utc)
    initial_status = "paid" if amount <= 0 else "created"

    order = OrderRecord(
        id=f"CW-{uuid.uuid4().hex[:10].upper()}",
        user_account_id=account.id,
        store_id=store.id,
        device_id=device["id"],
        package_id=package["id"],
        status=initial_status,
        amount=amount,
        remaining_seconds=int(package["minutes"]) * 60,
        used_free_wash_credit=body.used_free_wash_credit,
        paid_at=now if amount <= 0 else None,
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    payload = order_to_json(order)
    payload["free_wash_credits"] = account.free_wash_credits
    payload["prepaid_wash_credits"] = account.prepaid_wash_credits
    return payload


@router.patch("/api/orders/{order_id}")
def patch_order(
    order_id: str,
    body: UpdateOrderRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    order = _order_for_account(db, order_id, account)
    if body.status is not None:
        order.status = body.status.strip()
        if order.status == "paid" and order.paid_at is None:
            order.paid_at = datetime.now(timezone.utc)
    if body.payment_transaction_id is not None:
        order.payment_transaction_id = body.payment_transaction_id
    if body.payment_method is not None:
        order.payment_method = body.payment_method
    if body.provider_reference is not None:
        order.provider_reference = body.provider_reference
    db.commit()
    db.refresh(order)
    return order_to_json(order)


@router.post("/api/reservations")
def create_reservation(
    body: CreateReservationRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    if account.role != "user":
        raise HTTPException(status_code=400, detail="Only users can create reservations")

    store = db.get(StoreRecord, body.store_id.strip())
    if store is None or store.approval_status != "approved":
        raise HTTPException(status_code=404, detail="Store not found")
    if not body.contact_phone.strip():
        raise HTTPException(status_code=400, detail="Contact phone is required")

    reservation = ReservationRecord(
        id=f"RES-{uuid.uuid4().hex[:10].upper()}",
        user_account_id=account.id,
        store_id=store.id,
        service_type=body.service_type.strip(),
        user_latitude=body.user_latitude,
        user_longitude=body.user_longitude,
        distance_km=body.distance_km,
        eta_minutes=body.eta_minutes,
        arrival_time=body.arrival_time,
        contact_phone=body.contact_phone.strip(),
        note=body.note.strip(),
        status="pending",
    )
    db.add(reservation)
    db.commit()
    db.refresh(reservation)
    return reservation_to_json(reservation)


@router.patch("/api/reservations/{reservation_id}")
def patch_reservation(
    reservation_id: str,
    body: UpdateReservationRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    reservation = db.get(ReservationRecord, reservation_id)
    if reservation is None:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if account.role == "user" and reservation.user_account_id != account.id:
        raise HTTPException(status_code=403, detail="Not allowed to edit this reservation")
    if account.role == "shop":
        store = db.get(StoreRecord, reservation.store_id)
        if store is None or store.owner_account_id != account.id:
            raise HTTPException(status_code=403, detail="Not allowed to edit this reservation")
    if body.status is not None:
        reservation.status = body.status.strip()
    db.commit()
    db.refresh(reservation)
    return reservation_to_json(reservation)


@router.post("/api/vehicles")
def create_vehicle(
    body: CreateVehicleRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    if account.role != "user":
        raise HTTPException(status_code=400, detail="Only users can add vehicles")
    vehicle = VehicleRecord(
        id=f"VEH-{uuid.uuid4().hex[:10].upper()}",
        user_account_id=account.id,
        plate=body.plate.strip(),
        model=body.model.strip(),
        color=body.color.strip(),
    )
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle_to_json(vehicle)


@router.delete("/api/vehicles/{vehicle_id}")
def delete_vehicle(
    vehicle_id: str,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    vehicle = db.get(VehicleRecord, vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    if vehicle.user_account_id != account.id:
        raise HTTPException(status_code=403, detail="Not allowed to delete this vehicle")
    db.delete(vehicle)
    db.commit()
    return {"ok": True}


@router.post("/api/addresses")
def create_address(
    body: CreateAddressRequest,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    if account.role != "user":
        raise HTTPException(status_code=400, detail="Only users can add addresses")
    address = AddressRecord(
        id=f"ADDR-{uuid.uuid4().hex[:10].upper()}",
        user_account_id=account.id,
        label=body.label.strip(),
        address=body.address.strip(),
        latitude=body.latitude,
        longitude=body.longitude,
    )
    db.add(address)
    db.commit()
    db.refresh(address)
    return address_to_json(address)


@router.delete("/api/addresses/{address_id}")
def delete_address(
    address_id: str,
    db: Session = Depends(get_db),
    account: AccountRecord = Depends(get_current_account),
) -> dict:
    address = db.get(AddressRecord, address_id)
    if address is None:
        raise HTTPException(status_code=404, detail="Address not found")
    if address.user_account_id != account.id:
        raise HTTPException(status_code=403, detail="Not allowed to delete this address")
    db.delete(address)
    db.commit()
    return {"ok": True}
