import hashlib
import secrets
import uuid
import xml.etree.ElementTree as ET
from typing import Any

import httpx

from app.config import Settings


def _md5_sign(params: dict[str, Any], api_key: str) -> str:
    parts = []
    for key in sorted(params.keys()):
        value = params[key]
        if value is None or value == "" or key == "sign":
            continue
        parts.append(f"{key}={value}")
    parts.append(f"key={api_key}")
    return hashlib.md5("&".join(parts).encode("utf-8")).hexdigest().upper()


def _dict_to_xml(params: dict[str, Any]) -> str:
    items = "".join(f"<{k}>{v}</{k}>" for k, v in params.items())
    return f"<xml>{items}</xml>"


def _xml_to_dict(xml_text: str) -> dict[str, str]:
    root = ET.fromstring(xml_text)
    return {child.tag: child.text or "" for child in root}


class WeChatPayClient:
    UNIFIED_ORDER_URL = "https://api.mch.weixin.qq.com/pay/unifiedorder"
    ORDER_QUERY_URL = "https://api.mch.weixin.qq.com/pay/orderquery"

    def __init__(self, settings: Settings):
        self.settings = settings

    def create_app_prepay(
        self,
        *,
        out_trade_no: str,
        amount_yuan: float,
        description: str,
        notify_url: str,
    ) -> dict[str, Any]:
        total_fee = int(round(amount_yuan * 100))
        nonce_str = secrets.token_hex(16)
        params = {
            "appid": self.settings.wechat_app_id,
            "mch_id": self.settings.wechat_mch_id,
            "nonce_str": nonce_str,
            "body": description[:127],
            "out_trade_no": out_trade_no,
            "total_fee": str(total_fee),
            "spbill_create_ip": "127.0.0.1",
            "notify_url": notify_url,
            "trade_type": "APP",
        }
        params["sign"] = _md5_sign(params, self.settings.wechat_api_key)
        response = httpx.post(
            self.UNIFIED_ORDER_URL,
            content=_dict_to_xml(params).encode("utf-8"),
            headers={"Content-Type": "application/xml"},
            timeout=20,
        )
        response.raise_for_status()
        result = _xml_to_dict(response.text)
        if result.get("return_code") != "SUCCESS":
            raise RuntimeError(result.get("return_msg") or "WeChat unified order failed")
        if result.get("result_code") != "SUCCESS":
            raise RuntimeError(result.get("err_code_des") or "WeChat unified order rejected")

        prepay_id = result["prepay_id"]
        timestamp = str(int(__import__("time").time()))
        app_params = {
            "appid": self.settings.wechat_app_id,
            "partnerid": self.settings.wechat_mch_id,
            "prepayid": prepay_id,
            "package": "Sign=WXPay",
            "noncestr": secrets.token_hex(16),
            "timestamp": timestamp,
        }
        app_params["sign"] = _md5_sign(app_params, self.settings.wechat_api_key)
        return {
            "ready": True,
            "mode": "live",
            "appid": app_params["appid"],
            "partnerid": app_params["partnerid"],
            "prepayid": app_params["prepayid"],
            "package": app_params["package"],
            "noncestr": app_params["noncestr"],
            "timestamp": int(timestamp),
            "sign": app_params["sign"],
            "out_trade_no": out_trade_no,
        }

    def query_paid(self, out_trade_no: str) -> bool:
        params = {
            "appid": self.settings.wechat_app_id,
            "mch_id": self.settings.wechat_mch_id,
            "out_trade_no": out_trade_no,
            "nonce_str": secrets.token_hex(16),
        }
        params["sign"] = _md5_sign(params, self.settings.wechat_api_key)
        response = httpx.post(
            self.ORDER_QUERY_URL,
            content=_dict_to_xml(params).encode("utf-8"),
            headers={"Content-Type": "application/xml"},
            timeout=20,
        )
        response.raise_for_status()
        result = _xml_to_dict(response.text)
        return (
            result.get("return_code") == "SUCCESS"
            and result.get("result_code") == "SUCCESS"
            and result.get("trade_state") == "SUCCESS"
        )

    def parse_notify(self, xml_text: str) -> dict[str, str]:
        data = _xml_to_dict(xml_text)
        sign = data.pop("sign", "")
        expected = _md5_sign(data, self.settings.wechat_api_key)
        if sign != expected:
            raise ValueError("Invalid WeChat notify signature")
        return data
