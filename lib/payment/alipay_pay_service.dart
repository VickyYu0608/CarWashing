import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/payment/alipay_pay_cashier_page.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:flutter/material.dart';
import 'package:tobias/tobias.dart';

class AlipayPayResult {
  const AlipayPayResult({
    required this.success,
    this.providerReference,
    this.errorMessage,
    this.userCancelled = false,
  });

  final bool success;
  final String? providerReference;
  final String? errorMessage;
  final bool userCancelled;

  factory AlipayPayResult.success(String providerReference) =>
      AlipayPayResult(success: true, providerReference: providerReference);

  factory AlipayPayResult.cancelled() =>
      const AlipayPayResult(success: false, userCancelled: true);

  factory AlipayPayResult.failure(String message) =>
      AlipayPayResult(success: false, errorMessage: message);
}

class AlipayPayService {
  AlipayPayService._();

  static final AlipayPayService instance = AlipayPayService._();

  final Tobias _tobias = Tobias();
  String? _registeredAppId;

  Future<void> _ensureRegistered(String appId) async {
    if (_registeredAppId == appId) {
      return;
    }
    await _tobias.registerApp(appId);
    _registeredAppId = appId;
  }

  Future<bool> isAlipayInstalled() async {
    return _tobias.isAliPayInstalled;
  }

  Future<AlipayPayResult> pay({
    required BuildContext context,
    required PaymentSession session,
    required PaymentIntent intent,
  }) async {
    final prepay = await _fetchPrepayParams(session: session, intent: intent);
    if (prepay != null) {
      if (!await isAlipayInstalled()) {
        return AlipayPayResult.failure('未检测到支付宝 App，请先安装支付宝后再支付');
      }
      final appId = prepay['app_id']?.toString();
      if (appId != null && appId.isNotEmpty) {
        await _ensureRegistered(appId);
      }
      return _payWithSdk(prepay['order_string']?.toString() ?? '');
    }

    if (!context.mounted) {
      return AlipayPayResult.failure('支付页面已关闭');
    }

    final cashierApproved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlipayPayCashierPage(session: session),
      ),
    );

    if (cashierApproved == true) {
      return AlipayPayResult.success('ali_cashier_${intent.intentId}');
    }
    return AlipayPayResult.cancelled();
  }

  Future<Map<String, dynamic>?> _fetchPrepayParams({
    required PaymentSession session,
    required PaymentIntent intent,
  }) async {
    if (!ApiClient.useBackend) {
      return null;
    }
    try {
      final payload = await ApiClient.createAlipayPrepayOrder(
        orderId: session.orderId,
        amount: session.amount,
        description: session.productSummary,
        intentId: intent.intentId,
      );
      if (payload['ready'] == true) {
        return payload;
      }
      return null;
    } on ApiConnectionException {
      return null;
    } on ApiException {
      return null;
    }
  }

  Future<AlipayPayResult> _payWithSdk(String orderString) async {
    if (orderString.isEmpty) {
      return AlipayPayResult.failure('支付宝订单参数无效');
    }
    try {
      final result = await _tobias.pay(orderString);
      final status = result['resultStatus']?.toString();
      if (status == '9000') {
        return AlipayPayResult.success(
          'ali_sdk_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      if (status == '6001') {
        return AlipayPayResult.cancelled();
      }
      final memo = result['memo']?.toString();
      return AlipayPayResult.failure(
        memo?.isNotEmpty == true ? memo! : '支付宝支付失败（$status）',
      );
    } on Object catch (error) {
      return AlipayPayResult.failure('无法唤起支付宝收银台：$error');
    }
  }
}
