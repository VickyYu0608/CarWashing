import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.database import PaymentRecord, PaymentStatus
from app.services.alipay_pay import AlipayClient
from app.services.wechat_pay import WeChatPayClient


def _new_out_trade_no(order_id: str, intent_id: str) -> str:
    suffix = uuid.uuid4().hex[:8]
    base = f"{order_id}_{intent_id}"[-48:]
    return f"cw_{base}_{suffix}"


class PaymentService:
    def __init__(self, db: Session, settings: Settings | None = None):
        self.db = db
        self.settings = settings or get_settings()

    def config_payload(self) -> dict:
        return {
            "demo_mode": self.settings.payment_demo_mode,
            "wechat_ready": self.settings.wechat_ready,
            "alipay_ready": self.settings.alipay_ready,
            "public_base_url": self.settings.public_base_url,
        }

    def create_wechat_prepay(
        self,
        *,
        order_id: str,
        amount: float,
        description: str,
        intent_id: str,
    ) -> dict:
        if not self.settings.wechat_ready:
            return {"ready": False, "mode": "demo", "reason": "wechat_not_configured"}

        out_trade_no = _new_out_trade_no(order_id, intent_id)
        record = PaymentRecord(
            id=f"pay_{uuid.uuid4().hex}",
            order_id=order_id,
            intent_id=intent_id,
            method="wechat",
            amount=amount,
            description=description,
            status=PaymentStatus.pending.value,
            out_trade_no=out_trade_no,
            demo_mode=False,
        )
        self.db.add(record)
        self.db.commit()

        client = WeChatPayClient(self.settings)
        payload = client.create_app_prepay(
            out_trade_no=out_trade_no,
            amount_yuan=amount,
            description=description,
            notify_url=self.settings.resolved_wechat_notify_url,
        )
        payload["payment_id"] = record.id
        return payload

    def create_alipay_prepay(
        self,
        *,
        order_id: str,
        amount: float,
        description: str,
        intent_id: str,
    ) -> dict:
        if not self.settings.alipay_ready:
            return {"ready": False, "mode": "demo", "reason": "alipay_not_configured"}

        out_trade_no = _new_out_trade_no(order_id, intent_id)
        record = PaymentRecord(
            id=f"pay_{uuid.uuid4().hex}",
            order_id=order_id,
            intent_id=intent_id,
            method="alipay",
            amount=amount,
            description=description,
            status=PaymentStatus.pending.value,
            out_trade_no=out_trade_no,
            demo_mode=False,
        )
        self.db.add(record)
        self.db.commit()

        client = AlipayClient(self.settings)
        payload = client.create_app_order_string(
            out_trade_no=out_trade_no,
            amount_yuan=amount,
            subject=description,
        )
        payload["payment_id"] = record.id
        return payload

    def confirm_payment(
        self,
        *,
        order_id: str,
        intent_id: str,
        method: str,
        provider_reference: str,
        amount: float,
    ) -> dict:
        record = (
            self.db.query(PaymentRecord)
            .filter(
                PaymentRecord.order_id == order_id,
                PaymentRecord.intent_id == intent_id,
                PaymentRecord.method == method,
            )
            .order_by(PaymentRecord.created_at.desc())
            .first()
        )

        is_demo_reference = provider_reference.startswith(("wx_cashier_", "ali_cashier_"))

        if record is None and is_demo_reference and self.settings.payment_demo_mode:
            record = PaymentRecord(
                id=f"pay_{uuid.uuid4().hex}",
                order_id=order_id,
                intent_id=intent_id,
                method=method,
                amount=amount,
                description="demo cashier",
                status=PaymentStatus.pending.value,
                out_trade_no=_new_out_trade_no(order_id, intent_id),
                demo_mode=True,
            )
            self.db.add(record)
            self.db.flush()

        if record is None:
            raise ValueError("找不到支付记录，请重新发起支付")

        if abs(record.amount - amount) > 0.01:
            raise ValueError("支付金额与订单不一致")

        if record.status == PaymentStatus.paid.value:
            return self._success_payload(record)

        if record.demo_mode or is_demo_reference:
            if not self.settings.payment_demo_mode:
                raise ValueError("演示支付已关闭，请配置正式商户后重试")
            record.status = PaymentStatus.paid.value
            record.provider_reference = provider_reference
            record.transaction_id = provider_reference
            record.paid_at = datetime.now(timezone.utc)
            self.db.commit()
            return self._success_payload(record)

        verified = False
        if method == "wechat" and self.settings.wechat_ready:
            verified = WeChatPayClient(self.settings).query_paid(record.out_trade_no)
        elif method == "alipay" and self.settings.alipay_ready:
            verified = AlipayClient(self.settings).query_paid(record.out_trade_no)

        if not verified and record.status != PaymentStatus.paid.value:
            raise ValueError("支付尚未到账，请稍后在微信/支付宝完成付款后再试")

        record.status = PaymentStatus.paid.value
        record.provider_reference = provider_reference
        record.transaction_id = provider_reference
        record.paid_at = datetime.now(timezone.utc)
        self.db.commit()
        return self._success_payload(record)

    def mark_paid_from_notify(
        self,
        *,
        out_trade_no: str,
        transaction_id: str,
        provider_reference: str | None = None,
    ) -> None:
        record = (
            self.db.query(PaymentRecord)
            .filter(PaymentRecord.out_trade_no == out_trade_no)
            .first()
        )
        if record is None:
            return
        record.status = PaymentStatus.paid.value
        record.transaction_id = transaction_id
        record.provider_reference = provider_reference or transaction_id
        record.paid_at = datetime.now(timezone.utc)
        self.db.commit()

    def _success_payload(self, record: PaymentRecord) -> dict:
        return {
            "verified": True,
            "order_id": record.order_id,
            "transaction_id": record.transaction_id or record.provider_reference,
            "provider_reference": record.provider_reference,
            "paid_at": (record.paid_at or datetime.now(timezone.utc)).isoformat(),
            "method": record.method,
            "amount": record.amount,
        }
