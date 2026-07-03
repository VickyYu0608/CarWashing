import 'package:car_washing_app/payment/payment_models.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of attempting to open a third-party payment app on the device.
class PaymentExternalLaunchResult {
  const PaymentExternalLaunchResult({
    required this.launched,
    this.errorMessage,
  });

  final bool launched;
  final String? errorMessage;
}

/// Opens WeChat / Alipay on the device, similar to launching Google Maps.
///
/// Production WeChat Pay / Alipay merchant checkout still requires signed
/// order payloads from your backend (WeChat Pay SDK / Alipay SDK). This
/// launcher handles the user-visible redirect into the installed wallet app.
class PaymentExternalLauncher {
  PaymentExternalLauncher._();

  static Uri launchUriFor({
    required PaymentMethod method,
    required PaymentSession session,
  }) {
    return switch (method) {
      PaymentMethod.wechatPay => _weChatUri(session),
      PaymentMethod.alipay => _alipayUri(session),
      _ => throw ArgumentError('${method.name} does not support external launch'),
    };
  }

  static Uri _weChatUri(PaymentSession session) {
    // Opens WeChat. Merchant SDK integration replaces this with a signed
    // pay request (`fluwx` / WeChat Open SDK) once backend prepay is ready.
    return Uri.parse('weixin://');
  }

  static Uri _alipayUri(PaymentSession session) {
    // Opens Alipay pay / cashier module.
    return Uri.parse('alipays://platformapi/startapp?saId=10000007');
  }

  static Uri? storeListingUri(PaymentMethod method) {
    if (kIsWeb) {
      return null;
    }
    return switch (method) {
      PaymentMethod.wechatPay => Uri.parse(
          'https://play.google.com/store/apps/details?id=com.tencent.mm',
        ),
      PaymentMethod.alipay => Uri.parse(
          'https://play.google.com/store/apps/details?id=com.eg.android.AlipayGphone',
        ),
      _ => null,
    };
  }

  static Future<bool> isAppInstalled(PaymentMethod method) async {
    if (method != PaymentMethod.wechatPay && method != PaymentMethod.alipay) {
      return true;
    }
    final uri = launchUriFor(
      method: method,
      session: PaymentSession(
        sessionId: 'probe',
        orderId: 'probe',
        amount: 1,
        merchantName: 'probe',
        productSummary: 'probe',
        payerDisplayName: 'probe',
        payerPhoneMasked: 'probe',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      ),
    );
    return canLaunchUrl(uri);
  }

  static Future<PaymentExternalLaunchResult> launch({
    required PaymentMethod method,
    required PaymentSession session,
  }) async {
    if (method != PaymentMethod.wechatPay && method != PaymentMethod.alipay) {
      return const PaymentExternalLaunchResult(
        launched: false,
        errorMessage: '当前支付方式不支持外部 App 跳转',
      );
    }

    final uri = launchUriFor(method: method, session: session);

    try {
      if (!await canLaunchUrl(uri)) {
        return PaymentExternalLaunchResult(
          launched: false,
          errorMessage: method == PaymentMethod.wechatPay
              ? '未检测到微信 App，请先安装微信后再支付'
              : '未检测到支付宝 App，请先安装支付宝后再支付',
        );
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return PaymentExternalLaunchResult(
          launched: false,
          errorMessage: '无法打开${method.providerName}，请确认 App 已安装',
        );
      }
      return const PaymentExternalLaunchResult(launched: true);
    } on Object catch (error) {
      return PaymentExternalLaunchResult(
        launched: false,
        errorMessage: '跳转${method.providerName}失败：$error',
      );
    }
  }

  static Future<bool> openStoreListing(PaymentMethod method) async {
    final uri = storeListingUri(method);
    if (uri == null || !await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
