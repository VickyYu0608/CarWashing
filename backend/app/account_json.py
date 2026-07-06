from __future__ import annotations

from app.database import AccountRecord


def referred_user_id_list(account: AccountRecord) -> list[str]:
    if not account.referred_user_ids:
        return []
    return [item for item in account.referred_user_ids.split(",") if item]


def set_referred_user_ids(account: AccountRecord, user_ids: list[str]) -> None:
    account.referred_user_ids = ",".join(user_ids)


def account_to_json(account: AccountRecord) -> dict:
    return {
        "id": account.id,
        "username": account.username,
        "email": account.email,
        "country_code": account.country_code,
        "phone": account.phone,
        "role": account.role,
        "display_name": account.display_name,
        "approval_status": account.approval_status,
        "shop_address": account.shop_address,
        "shop_latitude": account.shop_latitude,
        "shop_longitude": account.shop_longitude,
        "share_code": account.share_code,
        "free_wash_credits": account.free_wash_credits,
        "prepaid_wash_credits": account.prepaid_wash_credits,
        "referred_by_user_id": account.referred_by_user_id,
        "referred_user_ids": referred_user_id_list(account),
        "auto_use_free_wash": account.auto_use_free_wash,
    }
