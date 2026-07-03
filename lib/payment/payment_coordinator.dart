import 'dart:math';

import 'package:car_washing_app/payment/payment_gateway.dart';
import 'package:car_washing_app/payment/payment_models.dart';

/// Orchestrates the full checkout lifecycle:
/// session → intent → provider auth → capture → server verify → receipt.
class PaymentCoordinator {
  PaymentCoordinator({PaymentGateway? gateway})
      : _gateway = gateway ?? SandboxPaymentGateway.instance;

  final PaymentGateway _gateway;
  PaymentSession? _activeSession;
  String? _activeIdempotencyKey;
  bool _isProcessing = false;

  PaymentSession? get activeSession => _activeSession;

  void reset() {
    _activeSession = null;
    _activeIdempotencyKey = null;
    _isProcessing = false;
  }

  PaymentSession createSession({
    required String orderId,
    required double amount,
    required String merchantName,
    required String productSummary,
    required String payerDisplayName,
    required String payerPhone,
  }) {
    final now = DateTime.now();
    _activeSession = PaymentSession(
      sessionId: 'ps_${now.millisecondsSinceEpoch}_${Random.secure().nextInt(9999)}',
      orderId: orderId,
      amount: amount,
      merchantName: merchantName,
      productSummary: productSummary,
      payerDisplayName: payerDisplayName,
      payerPhoneMasked: maskPhoneNumber(payerPhone),
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
      status: PaymentSessionStatus.created,
    );
    return _activeSession!;
  }

  String? validateBeforeCheckout({
    required PaymentMethod? method,
    required bool applePayAvailable,
    CreditCardInput? card,
  }) {
    final session = _activeSession;
    if (session == null) {
      return '支付会话不存在，请返回重新下单';
    }
    if (session.isExpired) {
      session.status = PaymentSessionStatus.expired;
      return '支付会话已过期（15 分钟），请返回重新下单';
    }
    return PaymentValidator.validateMethodSelection(
      method: method,
      amount: session.amount,
      applePayAvailable: applePayAvailable,
      card: card,
    );
  }

  Future<PaymentIntent> prepareIntent(PaymentMethod method) async {
    final session = _requireActiveSession();
    session.selectedMethod = method;
    session.status = PaymentSessionStatus.awaitingUserAction;
    return _gateway.createPaymentIntent(session: session, method: method);
  }

  Future<PaymentReceipt?> executeCheckout({
    required PaymentIntent intent,
    required ProviderAuthorizationResult authorization,
    CreditCardInput? card,
  }) async {
    if (_isProcessing) {
      throw StateError('付款处理中，请勿重复提交');
    }

    final session = _requireActiveSession();
    if (session.isExpired) {
      session.status = PaymentSessionStatus.expired;
      throw StateError('支付会话已过期，请返回重新下单');
    }

    final idempotencyKey = '${session.sessionId}_${intent.intentId}';
    if (_activeIdempotencyKey == idempotencyKey) {
      throw StateError('付款处理中，请勿重复提交');
    }
    _activeIdempotencyKey = idempotencyKey;
    _isProcessing = true;
    session.status = PaymentSessionStatus.processing;

    try {
      if (authorization.userCancelled) {
        session.status = PaymentSessionStatus.cancelled;
        throw StateError(authorization.errorMessage ?? '您已取消支付');
      }
      if (!authorization.approved || authorization.providerReference == null) {
        session.status = PaymentSessionStatus.failed;
        throw StateError(authorization.errorMessage ?? '支付授权失败');
      }

      if (card != null) {
        PaymentValidator.tokenizeCard(card);
      }

      final captureResult = await _gateway.capturePayment(
        session: session,
        intent: intent,
        providerReference: authorization.providerReference!,
        card: card,
      );

      if (!captureResult.success) {
        session.status = PaymentSessionStatus.failed;
        throw StateError(captureResult.errorMessage ?? '扣款失败');
      }

      final verified = await _gateway.verifyPaymentOnServer(
        result: captureResult,
        session: session,
      );
      if (!verified) {
        session.status = PaymentSessionStatus.failed;
        throw StateError('支付结果校验失败，请联系客服并提供订单号');
      }

      session.status = PaymentSessionStatus.succeeded;
      return PaymentReceipt(
        transactionId: captureResult.transactionId,
        providerReference: captureResult.providerReference!,
        orderId: session.orderId,
        amount: session.amount,
        method: intent.method,
        merchantName: session.merchantName,
        productSummary: session.productSummary,
        paidAt: captureResult.capturedAt ?? DateTime.now(),
      );
    } finally {
      _isProcessing = false;
      _activeIdempotencyKey = null;
    }
  }

  PaymentSession _requireActiveSession() {
    final session = _activeSession;
    if (session == null) {
      throw StateError('支付会话不存在');
    }
    return session;
  }
}
