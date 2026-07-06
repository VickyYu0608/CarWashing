from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Boolean, DateTime, Float, String, Text, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker

from app.config import get_settings


class Base(DeclarativeBase):
    pass


class PaymentStatus(str, Enum):
    pending = "pending"
    paid = "paid"
    failed = "failed"
    cancelled = "cancelled"


class PaymentRecord(Base):
    __tablename__ = "payment_records"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    order_id: Mapped[str] = mapped_column(String(64), index=True)
    intent_id: Mapped[str] = mapped_column(String(128), index=True)
    method: Mapped[str] = mapped_column(String(32))
    amount: Mapped[float] = mapped_column(Float)
    description: Mapped[str] = mapped_column(Text, default="")
    status: Mapped[str] = mapped_column(String(32), default=PaymentStatus.pending.value)
    provider_reference: Mapped[str | None] = mapped_column(String(128), nullable=True)
    transaction_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    out_trade_no: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    demo_mode: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class EmailVerification(Base):
    __tablename__ = "email_verifications"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(256), index=True)
    code: Mapped[str] = mapped_column(String(8))
    purpose: Mapped[str] = mapped_column(String(32), index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )


class AccountRecord(Base):
    __tablename__ = "accounts"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    username: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(256))
    email: Mapped[str] = mapped_column(String(256), unique=True, index=True)
    country_code: Mapped[str] = mapped_column(String(16), default="")
    phone: Mapped[str] = mapped_column(String(32), default="")
    role: Mapped[str] = mapped_column(String(16), index=True)
    display_name: Mapped[str] = mapped_column(String(128), default="")
    approval_status: Mapped[str] = mapped_column(String(32), default="approved")
    shop_address: Mapped[str] = mapped_column(Text, default="")
    shop_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    shop_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    share_code: Mapped[str] = mapped_column(String(32), default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )


class StoreRecord(Base):
    __tablename__ = "stores"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    owner_account_id: Mapped[str] = mapped_column(String(64), index=True)
    name: Mapped[str] = mapped_column(String(256))
    address: Mapped[str] = mapped_column(Text, default="")
    latitude: Mapped[float] = mapped_column(Float, default=0.0)
    longitude: Mapped[float] = mapped_column(Float, default=0.0)
    approval_status: Mapped[str] = mapped_column(String(32), default="pending")
    service_types: Mapped[str] = mapped_column(Text, default="")
    license_files: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )


settings = get_settings()
engine = create_engine(
    "sqlite:///./car_washing.db",
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def init_db() -> None:
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
