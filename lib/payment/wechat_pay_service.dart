import 'dart:async';

import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:car_washing_app/payment/wechat_pay_cashier_page.dart';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart';

class WeChatPayResult {
  const WeChatPayResult({
    required this.success,
    this.providerReference,
    this.errorMessage,
    this.userCancelled = false,
  });

  final bool success;
  final String? providerReference;
  final String? errorMessage;
  final bool userCancelled;

  factory WeChatPayResult.success(String providerReference) =>
      WeChatPayResult(success: true, providerReference: providerReference);

  factory WeChatPayResult.cancelled() =>
      const WeChatPayResult(success: false, userCancelled: true);

  factory WeChatPayResult.failure(String message) =>
      WeChatPayResult(success: false, errorMessage: message);
}

class WeChatPayService {
  WeChatPayService._();

  static final WeChatPayService instance = WeChatPayService._();

  final Fluwx _fluwx = Fluwx();
  String? _registeredAppId;
  FluwxCancelable? _responseSubscription;

  Future<void> _ensureRegistered(String appId) async {
    if (_registeredAppId == appId) {
      return;
    }
    await _fluwx.registerApi(appId: appId, doOnAndroid: true, doOnIOS: true);
    _registeredAppId = appId;
  }

  Future<bool> isWeChatInstalled() async {
    return _fluwx.isWeChatInstalled;
  }

  Future<WeChatPayResult> pay({
    required BuildContext context,
    required PaymentSession session,
    required PaymentIntent intent,
  }) async {
    final prepay = await _fetchPrepayParams(session: session, intent: intent);
    if (prepay != null) {
      if (!await isWeChatInstalled()) {
        return WeChatPayResult.failure('未检测到微信 App，请先安装微信后再支付');
      }
      await _ensureRegistered(prepay['appid']?.toString() ?? '');
      return _payWithSdk(prepay);
    }

    if (!context.mounted) {
      return WeChatPayResult.failure('支付页面已关闭');
    }

    final cashierApproved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WeChatPayCashierPage(session: session),
      ),
    );

    if (cashierApproved == true) {
      return WeChatPayResult.success('wx_cashier_${intent.intentId}');
    }
    return WeChatPayResult.cancelled();
  }

  Future<Map<String, dynamic>?> _fetchPrepayParams({
    required PaymentSession session,
    required PaymentIntent intent,
  }) async {
    if (!ApiClient.useBackend) {
      return null;
    }
    try {
      final payload = await ApiClient.createWeChatPrepayOrder(
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

  Future<WeChatPayResult> _payWithSdk(Map<String, dynamic> prepay) async {
    final completer = Completer<WeChatPayResult>();
    _responseSubscription?.cancel();
    _responseSubscription = _fluwx.addSubscriber((response) {
      if (response is! WeChatPaymentResponse || completer.isCompleted) {
        return;
      }
      if (response.isSuccessful) {
        completer.complete(
          WeChatPayResult.success(
            'wx_sdk_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      } else if (response.errCode == -2) {
        completer.complete(WeChatPayResult.cancelled());
      } else {
        completer.complete(
          WeChatPayResult.failure(
            response.errStr ?? '微信支付失败（${response.errCode}）',
          ),
        );
      }
    });

    final launched = await _fluwx.pay(
      which: Payment(
        appId: prepay['appid']?.toString() ?? '',
        partnerId: prepay['partnerid']?.toString() ?? '',
        prepayId: prepay['prepayid']?.toString() ?? '',
        packageValue: prepay['package']?.toString() ?? 'Sign=WXPay',
        nonceStr: prepay['noncestr']?.toString() ?? '',
        timestamp: _parseTimestamp(prepay['timestamp']),
        sign: prepay['sign']?.toString() ?? '',
        signType: prepay['signType']?.toString(),
      ),
    );

    if (!launched) {
      _responseSubscription?.cancel();
      return WeChatPayResult.failure('无法唤起微信收银台，请确认微信已安装');
    }

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _responseSubscription?.cancel();
        return WeChatPayResult.failure('微信支付超时，请重试');
      },
    );
  }

  int _parseTimestamp(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}
