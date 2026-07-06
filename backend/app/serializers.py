from __future__ import annotations

from app.database import (
    AddressRecord,
    OrderRecord,
    ReservationRecord,
    VehicleRecord,
    WalletBalanceRecord,
    WalletTransactionRecord,
)


def order_to_json(order: OrderRecord) -> dict:
    return {
        "id": order.id,
        "user_account_id": order.user_account_id,
        "store_id": order.store_id,
        "device_id": order.device_id,
        "package_id": order.package_id,
        "status": order.status,
        "amount": order.amount,
        "created_at": order.created_at.isoformat(),
        "started_at": order.started_at.isoformat() if order.started_at else None,
        "finished_at": order.finished_at.isoformat() if order.finished_at else None,
        "remaining_seconds": order.remaining_seconds,
        "failure_reason": order.failure_reason,
        "used_free_wash_credit": order.used_free_wash_credit,
        "payment_transaction_id": order.payment_transaction_id,
        "payment_method": order.payment_method,
        "provider_reference": order.provider_reference,
        "paid_at": order.paid_at.isoformat() if order.paid_at else None,
    }


def reservation_to_json(reservation: ReservationRecord) -> dict:
    return {
        "id": reservation.id,
        "user_account_id": reservation.user_account_id,
        "store_id": reservation.store_id,
        "service_type": reservation.service_type,
        "user_latitude": reservation.user_latitude,
        "user_longitude": reservation.user_longitude,
        "distance_km": reservation.distance_km,
        "eta_minutes": reservation.eta_minutes,
        "arrival_time": reservation.arrival_time.isoformat(),
        "contact_phone": reservation.contact_phone,
        "note": reservation.note,
        "status": reservation.status,
        "created_at": reservation.created_at.isoformat(),
    }


def vehicle_to_json(vehicle: VehicleRecord) -> dict:
    return {
        "id": vehicle.id,
        "plate": vehicle.plate,
        "model": vehicle.model,
        "color": vehicle.color,
    }


def address_to_json(address: AddressRecord) -> dict:
    return {
        "id": address.id,
        "label": address.label,
        "address": address.address,
        "latitude": address.latitude,
        "longitude": address.longitude,
    }


def wallet_to_json(
    balance: WalletBalanceRecord | None,
    transactions: list[WalletTransactionRecord],
) -> dict:
    return {
        "balance": balance.balance if balance is not None else 0.0,
        "transactions": [
            {
                "id": txn.id,
                "title": txn.title,
                "amount": txn.amount,
                "created_at": txn.created_at.isoformat(),
                "order_id": txn.order_id,
            }
            for txn in transactions
        ],
    }
