from __future__ import annotations

import logging
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import parseaddr

import httpx

from app.config import get_settings

logger = logging.getLogger(__name__)


def send_verification_email(*, to_email: str, code: str, purpose: str) -> None:
    settings = get_settings()
    subject, html = _build_message(code=code, purpose=purpose)
    from_header = settings.resolved_email_from

    if settings.resend_api_key:
        _send_resend(
            api_key=settings.resend_api_key,
            from_email=from_header,
            to_email=to_email,
            subject=subject,
            html=html,
        )
        return

    if settings.smtp_host and settings.smtp_user and settings.smtp_password:
        _, envelope_addr = parseaddr(from_header)
        envelope_addr = envelope_addr or settings.smtp_user
        _send_smtp(
            host=settings.smtp_host,
            port=settings.smtp_port,
            user=settings.smtp_user,
            password=settings.smtp_password,
            use_tls=settings.smtp_use_tls,
            from_header=from_header,
            envelope_from=envelope_addr,
            to_email=to_email,
            subject=subject,
            html=html,
        )
        return

    if settings.email_demo_mode:
        logger.warning(
            "EMAIL_DEMO_MODE: no mail provider configured; code for %s is %s",
            to_email,
            code,
        )
        return

    raise RuntimeError(
        "Email is not configured. Set RESEND_API_KEY or SMTP_* in backend/.env"
    )


def _build_message(*, code: str, purpose: str) -> tuple[str, str]:
    app_name = "Wash On Demand"
    if purpose == "register_shop":
        title = f"{app_name} — merchant registration"
        body = "Use this code to verify your merchant registration:"
    else:
        title = f"{app_name} — registration"
        body = "Use this code to verify your registration:"
    html = f"""
    <div style="font-family:sans-serif;max-width:480px">
      <h2>{title}</h2>
      <p>{body}</p>
      <p style="font-size:28px;font-weight:bold;letter-spacing:4px">{code}</p>
      <p style="color:#666">This code expires in 10 minutes. If you did not request it, ignore this email.</p>
      <p style="color:#999;font-size:12px">Please do not reply to this email.</p>
    </div>
    """
    return title, html


def _send_resend(
    *,
    api_key: str,
    from_email: str,
    to_email: str,
    subject: str,
    html: str,
) -> None:
    response = httpx.post(
        "https://api.resend.com/emails",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "from": from_email,
            "to": [to_email],
            "subject": subject,
            "html": html,
        },
        timeout=20.0,
    )
    if response.status_code >= 400:
        raise RuntimeError(f"Resend error ({response.status_code}): {response.text}")


def _send_smtp(
    *,
    host: str,
    port: int,
    user: str,
    password: str,
    use_tls: bool,
    from_header: str,
    envelope_from: str,
    to_email: str,
    subject: str,
    html: str,
) -> None:
    message = MIMEMultipart("alternative")
    message["Subject"] = subject
    message["From"] = from_header
    message["To"] = to_email
    message.attach(MIMEText(html, "html", "utf-8"))

    with smtplib.SMTP(host, port, timeout=20) as server:
        if use_tls:
            server.starttls()
        server.login(user, password)
        server.sendmail(envelope_from, [to_email], message.as_string())
