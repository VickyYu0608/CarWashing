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
