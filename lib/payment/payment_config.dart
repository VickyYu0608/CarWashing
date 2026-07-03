/// Payment provider credentials and feature flags.
///
/// Real WeChat Pay requires a registered WeChat Open Platform app id and a
/// backend that signs unified-order requests. Configure via:
///
/// ```bash
/// flutter run --dart-define=WECHAT_APP_ID=wxYOURAPPID
/// ```
class PaymentConfig {
  PaymentConfig._();

  static const weChatAppId = String.fromEnvironment(
    'WECHAT_APP_ID',
    defaultValue: '',
  );

  static const weChatUniversalLink = String.fromEnvironment(
    'WECHAT_UNIVERSAL_LINK',
    defaultValue: '',
  );

  static bool get hasWeChatAppId => weChatAppId.trim().isNotEmpty;
}
