from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import EmailVerification


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def _as_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def issue_code(db: Session, *, email: str, purpose: str, ttl_seconds: int) -> str:
    normalized = _normalize_email(email)
    code = f"{secrets.randbelow(1_000_000):06d}"
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)

    db.query(EmailVerification).filter(
        EmailVerification.email == normalized,
        EmailVerification.purpose == purpose,
        EmailVerification.used.is_(False),
    ).update({"used": True})

    db.add(
        EmailVerification(
            email=normalized,
            code=code,
            purpose=purpose,
            expires_at=expires_at,
            used=False,
        )
    )
    db.commit()
    return code


def verify_code(db: Session, *, email: str, code: str, purpose: str) -> bool:
    normalized = _normalize_email(email)
    now = datetime.now(timezone.utc)
    row = db.scalar(
        select(EmailVerification)
        .where(
            EmailVerification.email == normalized,
            EmailVerification.purpose == purpose,
            EmailVerification.used.is_(False),
        )
        .order_by(EmailVerification.created_at.desc())
        .limit(1)
    )
    if row is None:
        return False
    if _as_utc(row.expires_at) < now:
        return False
    if row.code != code.strip():
        return False
    row.used = True
    db.commit()
    return True
