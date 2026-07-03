/// Payment credentials are managed on the backend (`backend/.env`).
///
/// When merchant credentials are configured on the server, the app
/// automatically switches from demo cashier to live WeChat / Alipay SDK
/// checkout without any Flutter code changes.
class PaymentConfig {
  PaymentConfig._();
}
