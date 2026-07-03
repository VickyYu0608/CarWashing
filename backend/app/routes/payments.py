from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database import get_db
from app.services.alipay_pay import AlipayClient
from app.services.payment_service import PaymentService
from app.services.wechat_pay import WeChatPayClient

router = APIRouter(prefix="/api/payments", tags=["payments"])


class PrepayRequest(BaseModel):
    order_id: str
    amount: float = Field(gt=0)
    description: str = ""
    intent_id: str


class ConfirmRequest(BaseModel):
    order_id: str
    intent_id: str
    method: str
    provider_reference: str
    amount: float = Field(gt=0)


@router.get("/config")
def payment_config(db: Session = Depends(get_db)):
    return PaymentService(db).config_payload()


@router.post("/wechat/prepay")
def wechat_prepay(body: PrepayRequest, db: Session = Depends(get_db)):
    service = PaymentService(db)
    try:
        return service.create_wechat_prepay(
            order_id=body.order_id,
            amount=body.amount,
            description=body.description,
            intent_id=body.intent_id,
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=str(exc)) from exc


@router.post("/alipay/prepay")
def alipay_prepay(body: PrepayRequest, db: Session = Depends(get_db)):
    service = PaymentService(db)
    try:
        return service.create_alipay_prepay(
            order_id=body.order_id,
            amount=body.amount,
            description=body.description,
            intent_id=body.intent_id,
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=str(exc)) from exc


@router.post("/confirm")
def confirm_payment(body: ConfirmRequest, db: Session = Depends(get_db)):
    service = PaymentService(db)
    try:
        return service.confirm_payment(
            order_id=body.order_id,
            intent_id=body.intent_id,
            method=_normalize_method(body.method),
            provider_reference=body.provider_reference,
            amount=body.amount,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/wechat/notify")
async def wechat_notify(request: Request, db: Session = Depends(get_db)):
    settings = get_settings()
    if not settings.wechat_ready:
        return {"return_code": "FAIL", "return_msg": "not configured"}

    xml_text = (await request.body()).decode("utf-8")
    data = WeChatPayClient(settings).parse_notify(xml_text)
    if data.get("result_code") == "SUCCESS":
        PaymentService(db).mark_paid_from_notify(
            out_trade_no=data.get("out_trade_no", ""),
            transaction_id=data.get("transaction_id", ""),
            provider_reference=data.get("transaction_id"),
        )
    return (
        "<xml><return_code><![CDATA[SUCCESS]]></return_code>"
        "<return_msg><![CDATA[OK]]></return_msg></xml>"
    )


@router.post("/alipay/notify")
async def alipay_notify(request: Request, db: Session = Depends(get_db)):
    settings = get_settings()
    if not settings.alipay_ready:
        return "failure"

    form = dict(await request.form())
    data = {k: str(v) for k, v in form.items()}
    verified = AlipayClient(settings).verify_notify(data)
    if verified.get("trade_status") in {"TRADE_SUCCESS", "TRADE_FINISHED"}:
        PaymentService(db).mark_paid_from_notify(
            out_trade_no=verified.get("out_trade_no", ""),
            transaction_id=verified.get("trade_no", ""),
            provider_reference=verified.get("trade_no"),
        )
    return "success"


def _normalize_method(method: str) -> str:
    value = method.lower()
    if "wechat" in value or value == "wx":
        return "wechat"
    if "alipay" in value or value == "ali":
        return "alipay"
    return value
