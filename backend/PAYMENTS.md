# 支付正式启用指南

申请好微信 / 支付宝商户后，**只需修改 `backend/.env`，重启后端**，App 会自动切换为正式支付，无需改 Flutter 代码。

## 1. 复制配置文件

```bash
cd backend
copy .env.example .env
```

## 2. 启动后端

```bash
pip install -r requirements.txt
python run.py
```

默认地址：`http://127.0.0.1:8000`

## 3. 申请商户后填写 `.env`

### 微信支付

```env
WECHAT_APP_ID=wxXXXXXXXX
WECHAT_MCH_ID=1234567890
WECHAT_API_KEY=your_v2_api_key
PUBLIC_BASE_URL=https://your-domain.com
PAYMENT_DEMO_MODE=false
```

### 支付宝

```env
ALIPAY_APP_ID=2021XXXXXXXX
ALIPAY_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----
ALIPAY_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
PUBLIC_BASE_URL=https://your-domain.com
PAYMENT_DEMO_MODE=false
```

## 4. 自动切换逻辑

| 后端状态 | App 行为 |
|---------|---------|
| 商户未配置 | 演示收银台（金额 + 密码，不真实扣款） |
| 商户已配置 | 跳转微信 / 支付宝 **官方 App 收银台** |
| 支付完成 | 后端 `/api/payments/confirm` 验单后订单标记已支付 |

## 5. 验证是否就绪

```bash
curl http://127.0.0.1:8000/api/payments/config
```

返回示例：

```json
{
  "demo_mode": false,
  "wechat_ready": true,
  "alipay_ready": true
}
```

## 6. 平台侧还需完成

- 微信 / 支付宝开放平台绑定 App 与商户号
- 登记 **正式 APK 签名**（微信必须）
- 配置异步通知 URL（默认 `{PUBLIC_BASE_URL}/api/payments/wechat/notify` 和 `/alipay/notify`）
