from __future__ import annotations

import json
from pathlib import Path

from app.demo_catalog import BUNDLE_PLAN_DEFAULTS

_OVERRIDES_PATH = Path(__file__).resolve().parent.parent / "bundle_overrides.json"


def _load_overrides() -> dict[str, dict]:
    if not _OVERRIDES_PATH.exists():
        return {}
    try:
        return json.loads(_OVERRIDES_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def _save_overrides(data: dict[str, dict]) -> None:
    _OVERRIDES_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def list_bundle_plans() -> list[dict]:
    overrides = _load_overrides()
    plans: list[dict] = []
    for plan in BUNDLE_PLAN_DEFAULTS:
        merged = dict(plan)
        override = overrides.get(plan["id"])
        if override:
            merged.update(override)
        plans.append(merged)
    return plans


def update_bundle_plan(
    *,
    plan_id: str,
    price: float | None = None,
    wash_count: int | None = None,
    name: str | None = None,
) -> dict:
    base = next((p for p in BUNDLE_PLAN_DEFAULTS if p["id"] == plan_id), None)
    if base is None:
        raise ValueError("Package not found")

    overrides = _load_overrides()
    current = dict(overrides.get(plan_id, {}))
    if price is not None:
        current["price"] = price
    if wash_count is not None:
        current["wash_count"] = wash_count
    if name is not None:
        current["name"] = name
    overrides[plan_id] = current
    _save_overrides(overrides)

    merged = dict(base)
    merged.update(current)
    return merged
