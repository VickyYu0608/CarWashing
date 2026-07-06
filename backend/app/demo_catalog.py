from __future__ import annotations

from datetime import datetime, timezone

from app.database import StoreRecord
from app.package_store import get_store_overrides

DEFAULT_PACKAGES = [
    {
        "id": "quick",
        "name": "快速冲洗",
        "minutes": 8,
        "price": 12.0,
        "description": "适合轻度灰尘快速清洁",
    },
    {
        "id": "basic",
        "name": "标准自助洗",
        "minutes": 12,
        "price": 18.0,
        "description": "高压水枪、泡沫、清水冲洗",
    },
    {
        "id": "premium",
        "name": "精洗套餐",
        "minutes": 20,
        "price": 32.0,
        "description": "含泡沫、镀膜水蜡和吸尘",
    },
]

BUNDLE_PLAN_DEFAULTS = [
    {"id": "single", "wash_count": 1, "price": 50.0},
    {"id": "pack10", "wash_count": 10, "price": 450.0},
    {"id": "pack20", "wash_count": 20, "price": 850.0},
]

# Backwards-compatible alias used by purchase logic.
BUNDLE_PLANS = BUNDLE_PLAN_DEFAULTS

_DEVICE_PRESETS: dict[str, list[dict]] = {
    "store-1": [
        {
            "id": "D-1001",
            "qr_code": "CARWASH-1001",
            "bay_name": "自助1号",
            "status": "idle",
        },
        {
            "id": "D-1002",
            "qr_code": "CARWASH-1002",
            "bay_name": "自助2号",
            "status": "busy",
        },
        {
            "id": "D-1003",
            "qr_code": "CARWASH-1003",
            "bay_name": "自助3号",
            "status": "idle",
        },
    ],
    "store-2": [
        {
            "id": "D-2001",
            "qr_code": "CARWASH-2001",
            "bay_name": "自助A工位",
            "status": "idle",
        },
        {
            "id": "D-2002",
            "qr_code": "CARWASH-2002",
            "bay_name": "自助B工位",
            "status": "faulted",
        },
    ],
    "store-3": [
        {
            "id": "D-3001",
            "qr_code": "CARWASH-3001",
            "bay_name": "人工接待位",
            "status": "offline",
        },
    ],
}

_STORE_META: dict[str, dict] = {
    "store-1": {
        "rating": 4.8,
        "tags": ["24小时", "自助", "空闲多"],
    },
    "store-2": {
        "rating": 4.6,
        "tags": ["人工精洗", "自助吸尘"],
    },
    "store-3": {
        "rating": 4.5,
        "tags": ["人工洗车", "商场停车场"],
    },
}


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _devices_for_store(store: StoreRecord) -> list[dict]:
    presets = _DEVICE_PRESETS.get(store.id)
    if presets is None:
        suffix = store.id.rsplit("-", 1)[-1][:4]
        presets = [
            {
                "id": f"D-{suffix}",
                "qr_code": f"CARWASH-{suffix}",
                "bay_name": "自助1号",
                "status": "idle",
            }
        ]
    now = _now_iso()
    return [
        {
            **device,
            "last_heartbeat": now,
            "total_use_seconds": 0,
            "use_count": 0,
            "fault_count": 0,
        }
        for device in presets
    ]


def _packages_for_store(store: StoreRecord) -> list[dict]:
    overrides = get_store_overrides(store.id)
    packages: list[dict] = []
    for pkg in DEFAULT_PACKAGES:
        merged = dict(pkg)
        override = overrides.get(pkg["id"])
        if override:
            merged.update(override)
        packages.append(merged)
    return packages


def store_to_json(store: StoreRecord) -> dict:
    service_types = [
        item.strip()
        for item in store.service_types.split(",")
        if item.strip()
    ]
    if not service_types:
        service_types = ["self_service"]
    meta = _STORE_META.get(store.id, {"rating": 5.0, "tags": ["自助洗车"]})
    return {
        "id": store.id,
        "owner_account_id": store.owner_account_id,
        "name": store.name,
        "address": store.address,
        "latitude": store.latitude,
        "longitude": store.longitude,
        "rating": meta["rating"],
        "tags": meta["tags"],
        "service_types": service_types,
        "devices": _devices_for_store(store),
        "packages": _packages_for_store(store),
        "approval_status": store.approval_status,
        "admin_reply": "",
    }
