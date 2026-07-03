import 'package:car_washing_app/payment/payment_external_launcher.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds WeChat launch uri', () {
    final uri = PaymentExternalLauncher.launchUriFor(
      method: PaymentMethod.wechatPay,
      session: _session(),
    );
    expect(uri.scheme, 'weixin');
  });

  test('builds Alipay launch uri', () {
    final uri = PaymentExternalLauncher.launchUriFor(
      method: PaymentMethod.alipay,
      session: _session(),
    );
    expect(uri.scheme, 'alipays');
  });
}

PaymentSession _session() {
  final now = DateTime.now();
  return PaymentSession(
    sessionId: 'ps_test',
    orderId: 'order_test',
    amount: 18,
    merchantName: '测试洗车店',
    productSummary: '标准套餐',
    payerDisplayName: '测试用户',
    payerPhoneMasked: '138****0000',
    createdAt: now,
    expiresAt: now.add(const Duration(minutes: 15)),
  );
}
