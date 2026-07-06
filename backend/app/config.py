from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    api_host: str = "0.0.0.0"
    api_port: int = 8000
    public_base_url: str = "http://127.0.0.1:8000"
    jwt_secret: str = "dev-secret-change-me"
    payment_demo_mode: bool = True

    wechat_app_id: str = ""
    wechat_mch_id: str = ""
    wechat_api_key: str = ""
    wechat_notify_url: str = ""

    alipay_app_id: str = ""
    alipay_private_key: str = ""
    alipay_public_key: str = ""
    alipay_notify_url: str = ""

    # Email verification (Resend API or SMTP — see backend/.env.example)
    email_demo_mode: bool = True
    resend_api_key: str = ""
    email_from: str = "onboarding@resend.dev"
    email_from_name: str = "noreply"
    email_from_address: str = ""
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_use_tls: bool = True
    verification_code_ttl_seconds: int = 600

    @property
    def email_ready(self) -> bool:
        if self.resend_api_key:
            return bool(self.resolved_email_from)
        if self.smtp_host and self.smtp_user and self.smtp_password:
            return bool(self.smtp_user)
        return False

    @property
    def resolved_email_from(self) -> str:
        """RFC5322 From header value (display name + address)."""
        from email.utils import formataddr

        if self.resend_api_key:
            return self.email_from

        envelope = self.email_from_address.strip() or self.smtp_user or self.email_from
        return formataddr((self.email_from_name, envelope))

    @property
    def wechat_ready(self) -> bool:
        return all([self.wechat_app_id, self.wechat_mch_id, self.wechat_api_key])

    @property
    def alipay_ready(self) -> bool:
        return all([self.alipay_app_id, self.alipay_private_key, self.alipay_public_key])

    @property
    def resolved_wechat_notify_url(self) -> str:
        return self.wechat_notify_url or f"{self.public_base_url.rstrip('/')}/api/payments/wechat/notify"

    @property
    def resolved_alipay_notify_url(self) -> str:
        return self.alipay_notify_url or f"{self.public_base_url.rstrip('/')}/api/payments/alipay/notify"


@lru_cache
def get_settings() -> Settings:
    return Settings()
