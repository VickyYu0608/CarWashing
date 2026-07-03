from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException
from jose import jwt
from pydantic import BaseModel

from app.config import get_settings

router = APIRouter(prefix="/api/auth", tags=["auth"])

DEMO_USERS = {
    "user": {"password": "123456", "role": "user", "display_name": "测试用户"},
    "shop": {"password": "123456", "role": "shop", "display_name": "测试商家"},
    "admin": {"password": "123456", "role": "admin", "display_name": "Admin"},
}


class LoginRequest(BaseModel):
    username: str
    password: str


@router.post("/login")
def login(body: LoginRequest):
    account = DEMO_USERS.get(body.username.strip())
    if account is None or account["password"] != body.password:
        raise HTTPException(status_code=401, detail="账号或密码不匹配")

    settings = get_settings()
    token = jwt.encode(
        {
            "sub": body.username.strip(),
            "role": account["role"],
            "exp": datetime.now(timezone.utc) + timedelta(days=7),
        },
        settings.jwt_secret,
        algorithm="HS256",
    )
    return {"access_token": token, "token_type": "bearer"}


@router.get("/me")
def me():
    return {
        "username": "user",
        "display_name": "测试用户",
        "role": "user",
        "approval_status": "approved",
    }
