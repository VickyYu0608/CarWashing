from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import BundlePlanOverrideRecord
from app.demo_catalog import BUNDLE_PLAN_DEFAULTS


def list_bundle_plans(db: Session) -> list[dict]:
    rows = db.scalars(select(BundlePlanOverrideRecord)).all()
    overrides = {row.plan_id: _override_to_dict(row) for row in rows}
    plans: list[dict] = []
    for plan in BUNDLE_PLAN_DEFAULTS:
        merged = dict(plan)
        override = overrides.get(plan["id"])
        if override:
            merged.update({k: v for k, v in override.items() if v is not None})
        plans.append(merged)
    return plans


def update_bundle_plan(
    db: Session,
    *,
    plan_id: str,
    price: float | None = None,
    wash_count: int | None = None,
    name: str | None = None,
) -> dict:
    base = next((plan for plan in BUNDLE_PLAN_DEFAULTS if plan["id"] == plan_id), None)
    if base is None:
        raise ValueError("Package not found")

    row = db.get(BundlePlanOverrideRecord, plan_id)
    if row is None:
        row = BundlePlanOverrideRecord(plan_id=plan_id)
        db.add(row)
    if price is not None:
        row.price = price
    if wash_count is not None:
        row.wash_count = wash_count
    if name is not None:
        row.name = name
    db.commit()
    db.refresh(row)

    merged = dict(base)
    merged.update({k: v for k, v in _override_to_dict(row).items() if v is not None})
    return merged


def _override_to_dict(row: BundlePlanOverrideRecord) -> dict:
    return {
        "name": row.name,
        "wash_count": row.wash_count,
        "price": row.price,
    }
