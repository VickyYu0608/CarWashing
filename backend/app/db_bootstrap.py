from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

import pymysql
from sqlalchemy import func, select, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database import (
    AccountRecord,
    AddressRecord,
    Base,
    BundlePlanOverrideRecord,
    EmailVerification,
    OrderRecord,
    PaymentRecord,
    ReservationRecord,
    StoreDeviceRecord,
    StorePackageOverrideRecord,
    StoreRecord,
    VehicleRecord,
    WalletBalanceRecord,
    WalletTransactionRecord,
)


def _parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed


def ensure_mysql_database() -> None:
    settings = get_settings()
    connection = pymysql.connect(
        host=settings.mysql_host,
        port=settings.mysql_port,
        user=settings.mysql_user,
        password=settings.mysql_password,
        charset="utf8mb4",
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS `{settings.mysql_database}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
        connection.commit()
    finally:
        connection.close()


def bootstrap_database(engine: Engine) -> None:
    ensure_mysql_database()
    Base.metadata.create_all(bind=engine)
    with Session(engine) as db:
        migrate_legacy_data(db)


def migrate_legacy_data(db: Session) -> None:
    if _account_count(db) > 0:
        return
    migrated = _migrate_sqlite(db)
    if not migrated:
        _migrate_json_overrides(db)


def _account_count(db: Session) -> int:
    return int(db.scalar(select(func.count()).select_from(AccountRecord)) or 0)


def _migrate_sqlite(db: Session) -> bool:
    sqlite_path = Path(__file__).resolve().parent.parent / "car_washing.db"
    if not sqlite_path.exists():
        return False

    source = sqlite3.connect(sqlite_path)
    source.row_factory = sqlite3.Row
    try:
        if not _sqlite_table_exists(source, "accounts"):
            return False
        if source.execute("SELECT COUNT(*) FROM accounts").fetchone()[0] == 0:
            return False

        for row in source.execute("SELECT * FROM accounts").fetchall():
            data = dict(row)
            db.merge(
                AccountRecord(
                    id=data["id"],
                    username=data["username"],
                    password_hash=data["password_hash"],
                    email=data["email"],
                    country_code=data.get("country_code") or "",
                    phone=data.get("phone") or "",
                    role=data["role"],
                    display_name=data.get("display_name") or "",
                    approval_status=data.get("approval_status") or "approved",
                    shop_address=data.get("shop_address") or "",
                    shop_latitude=data.get("shop_latitude"),
                    shop_longitude=data.get("shop_longitude"),
                    share_code=data.get("share_code") or "",
                    free_wash_credits=data.get("free_wash_credits") or 0,
                    prepaid_wash_credits=data.get("prepaid_wash_credits") or 0,
                    referred_by_user_id=data.get("referred_by_user_id"),
                    referred_user_ids=data.get("referred_user_ids") or "",
                    auto_use_free_wash=bool(data.get("auto_use_free_wash", True)),
                    created_at=_parse_datetime(data.get("created_at"))
                    or datetime.now(timezone.utc),
                )
            )

        if _sqlite_table_exists(source, "stores"):
            for row in source.execute("SELECT * FROM stores").fetchall():
                data = dict(row)
                db.merge(
                    StoreRecord(
                        id=data["id"],
                        owner_account_id=data["owner_account_id"],
                        name=data["name"],
                        address=data.get("address") or "",
                        latitude=data.get("latitude") or 0.0,
                        longitude=data.get("longitude") or 0.0,
                        approval_status=data.get("approval_status") or "pending",
                        service_types=data.get("service_types") or "",
                        license_files=data.get("license_files") or "",
                        created_at=_parse_datetime(data.get("created_at"))
                        or datetime.now(timezone.utc),
                    )
                )

        if _sqlite_table_exists(source, "email_verifications"):
            for row in source.execute("SELECT * FROM email_verifications").fetchall():
                data = dict(row)
                db.add(
                    EmailVerification(
                        email=data["email"],
                        code=data["code"],
                        purpose=data["purpose"],
                        expires_at=_parse_datetime(data.get("expires_at"))
                        or datetime.now(timezone.utc),
                        used=bool(data.get("used")),
                        created_at=_parse_datetime(data.get("created_at"))
                        or datetime.now(timezone.utc),
                    )
                )

        if _sqlite_table_exists(source, "payment_records"):
            for row in source.execute("SELECT * FROM payment_records").fetchall():
                data = dict(row)
                db.merge(
                    PaymentRecord(
                        id=data["id"],
                        order_id=data["order_id"],
                        intent_id=data["intent_id"],
                        method=data["method"],
                        amount=data["amount"],
                        description=data.get("description") or "",
                        status=data.get("status") or "pending",
                        provider_reference=data.get("provider_reference"),
                        transaction_id=data.get("transaction_id"),
                        out_trade_no=data["out_trade_no"],
                        demo_mode=bool(data.get("demo_mode")),
                        created_at=_parse_datetime(data.get("created_at"))
                        or datetime.now(timezone.utc),
                        paid_at=_parse_datetime(data.get("paid_at")),
                    )
                )

        db.flush()
        _migrate_json_overrides(db)
        db.commit()
        return True
    finally:
        source.close()


def _sqlite_table_exists(connection: sqlite3.Connection, table: str) -> bool:
    row = connection.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return row is not None


def _migrate_json_overrides(db: Session) -> None:
    backend_root = Path(__file__).resolve().parent.parent
    bundle_path = backend_root / "bundle_overrides.json"
    if bundle_path.exists():
        try:
            bundle_data = json.loads(bundle_path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            bundle_data = {}
        for plan_id, override in bundle_data.items():
            db.merge(
                BundlePlanOverrideRecord(
                    plan_id=plan_id,
                    name=override.get("name"),
                    wash_count=override.get("wash_count"),
                    price=override.get("price"),
                )
            )

    package_path = backend_root / "package_overrides.json"
    if package_path.exists():
        try:
            package_data = json.loads(package_path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            package_data = {}
        for store_id, packages in package_data.items():
            for package_id, override in packages.items():
                db.merge(
                    StorePackageOverrideRecord(
                        store_id=store_id,
                        package_id=package_id,
                        name=override.get("name"),
                        minutes=override.get("minutes"),
                        price=override.get("price"),
                    )
                )

    db.commit()
