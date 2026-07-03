from typing import Any

from alipay import AliPay
from alipay.utils import AliPayConfig

from app.config import Settings


class AlipayClient:
    def __init__(self, settings: Settings):
        self.settings = settings
        self._client = AliPay(
            appid=settings.alipay_app_id,
            app_notify_url=settings.resolved_alipay_notify_url,
            app_private_key_string=settings.alipay_private_key,
            alipay_public_key_string=settings.alipay_public_key,
            sign_type="RSA2",
            debug=False,
            config=AliPayConfig(timeout=20),
        )

    def create_app_order_string(
        self,
        *,
        out_trade_no: str,
        amount_yuan: float,
        subject: str,
    ) -> dict[str, Any]:
        order_string = self._client.api_alipay_trade_app_pay(
            out_trade_no=out_trade_no,
            total_amount=f"{amount_yuan:.2f}",
            subject=subject[:256],
            notify_url=self.settings.resolved_alipay_notify_url,
        )
        return {
            "ready": True,
            "mode": "live",
            "app_id": self.settings.alipay_app_id,
            "order_string": order_string,
            "out_trade_no": out_trade_no,
        }

    def query_paid(self, out_trade_no: str) -> bool:
        result = self._client.api_alipay_trade_query(out_trade_no=out_trade_no)
        return result.get("trade_status") in {"TRADE_SUCCESS", "TRADE_FINISHED"}

    def verify_notify(self, data: dict[str, str]) -> dict[str, str]:
        signature = data.pop("sign", None)
        if not self._client.verify(data, signature):
            raise ValueError("Invalid Alipay notify signature")
        return data
