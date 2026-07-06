from __future__ import annotations

import json
from pathlib import Path

_OVERRIDES_PATH = Path(__file__).resolve().parent.parent / "package_overrides.json"


def _load_all() -> dict[str, dict[str, dict]]:
    if not _OVERRIDES_PATH.exists():
        return {}
    try:
        return json.loads(_OVERRIDES_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def _save_all(data: dict[str, dict[str, dict]]) -> None:
    _OVERRIDES_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def get_store_overrides(store_id: str) -> dict[str, dict]:
    return dict(_load_all().get(store_id, {}))


def update_package(
    *,
    store_id: str,
    package_id: str,
    price: float | None = None,
    minutes: int | None = None,
    name: str | None = None,
) -> dict:
    all_data = _load_all()
    store_data = dict(all_data.get(store_id, {}))
    current = dict(store_data.get(package_id, {}))
    if price is not None:
        current["price"] = price
    if minutes is not None:
        current["minutes"] = minutes
    if name is not None:
        current["name"] = name
    store_data[package_id] = current
    all_data[store_id] = store_data
    _save_all(all_data)
    return current
