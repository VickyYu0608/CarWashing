from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import StorePackageOverrideRecord


def get_store_overrides(db: Session, store_id: str) -> dict[str, dict]:
    rows = db.scalars(
        select(StorePackageOverrideRecord).where(
            StorePackageOverrideRecord.store_id == store_id
        )
    ).all()
    return {
        row.package_id: {
            key: value
            for key, value in {
                "name": row.name,
                "minutes": row.minutes,
                "price": row.price,
            }.items()
            if value is not None
        }
        for row in rows
    }


def update_package(
    db: Session,
    *,
    store_id: str,
    package_id: str,
    price: float | None = None,
    minutes: int | None = None,
    name: str | None = None,
) -> dict:
    row = db.get(StorePackageOverrideRecord, (store_id, package_id))
    if row is None:
        row = StorePackageOverrideRecord(store_id=store_id, package_id=package_id)
        db.add(row)
    if price is not None:
        row.price = price
    if minutes is not None:
        row.minutes = minutes
    if name is not None:
        row.name = name
    db.commit()
    db.refresh(row)
    return {
        key: value
        for key, value in {
            "name": row.name,
            "minutes": row.minutes,
            "price": row.price,
        }.items()
        if value is not None
    }
