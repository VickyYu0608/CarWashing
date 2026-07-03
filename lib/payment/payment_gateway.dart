import 'dart:math';

import 'package:car_washing_app/payment/payment_models.dart';

/// Production payment gateways (Alipay SDK, WeChat Pay SDK, Stripe, etc.)
/// should implement this contract. The sandbox gateway below mirrors their
/// redirect + callback + server-capture sequence without handling secrets
/// inside the merchant UI.
abstract class PaymentGateway {
  Future<PaymentIntent> createPaymentIntent({
    required PaymentSession session,
    required PaymentMethod method,
  });

  Future<ProviderAuthorizationResult> authorizeWithProvider({
    required ProviderAuthorizationRequest request,
    required bool userConfirmedInProvider,
    bool biometricConfirmed = false,
  });

  Future<PaymentResult> capturePayment({
    required PaymentSession session,
    required PaymentIntent intent,
    required String providerReference,
    CreditCardInput? card,
  });

  Future<bool> verifyPaymentOnServer({
    required PaymentResult result,
    required PaymentSession session,
  });
}

class SandboxPaymentGateway implements PaymentGateway {
  SandboxPaymentGateway._();

  static final SandboxPaymentGateway instance = SandboxPaymentGateway._();

  static const Duration authorizationDelay = Duration(milliseconds: 800);
  static const Duration captureDelay = Duration(milliseconds: 1200);
  static const Duration verifyDelay = Duration(milliseconds: 600);

  @override
  Future<PaymentIntent> createPaymentIntent({
    required PaymentSession session,
    required PaymentMethod method,
  }) async {
    if (session.isExpired) {
      throw StateError('支付会话已过期，请返回重新下单');
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return PaymentIntent(
      intentId: 'pi_${session.sessionId}_${method.name}',
      sessionId: session.sessionId,
      method: method,
      amount: session.amount,
      merchantReference: session.orderId,
    );
  }

  @override
  Future<ProviderAuthorizationResult> authorizeWithProvider({
    required ProviderAuthorizationRequest request,
    required bool userConfirmedInProvider,
    bool biometricConfirmed = false,
  }) async {
    await Future<void>.delayed(authorizationDelay);

    if (!userConfirmedInProvider) {
      return ProviderAuthorizationResult.cancelled();
    }

    return switch (request.intent.method) {
      PaymentMethod.alipay => ProviderAuthorizationResult.approved(
          'alipay_auth_${request.intent.intentId}',
        ),
      PaymentMethod.wechatPay => ProviderAuthorizationResult.approved(
          'wx_auth_${request.intent.intentId}',
        ),
      PaymentMethod.applePay => biometricConfirmed
          ? ProviderAuthorizationResult.approved(
              'apple_auth_${request.intent.intentId}',
            )
          : ProviderAuthorizationResult.rejected(
              'Apple Pay 生物识别验证未通过',
            ),
      PaymentMethod.creditCard => ProviderAuthorizationResult.approved(
          'card_auth_${request.intent.intentId}',
        ),
    };
  }

  @override
  Future<PaymentResult> capturePayment({
    required PaymentSession session,
    required PaymentIntent intent,
    required String providerReference,
    CreditCardInput? card,
  }) async {
    if (session.amount != intent.amount) {
      return PaymentResult.failure(
        code: 'AMOUNT_MISMATCH',
        message: '订单金额校验失败，请重新发起支付',
      );
    }

    await Future<void>.delayed(captureDelay);

    if (intent.method == PaymentMethod.creditCard && card != null) {
      final failure = _cardCaptureFailure(card);
      if (failure != null) {
        return failure;
      }
    }

    final now = DateTime.now();
    return PaymentResult.success(
      transactionId: _generateTransactionId(intent.method),
      method: intent.method,
      providerReference: providerReference,
      authorizedAt: now.subtract(const Duration(seconds: 2)),
      capturedAt: now,
    );
  }

  PaymentResult? _cardCaptureFailure(CreditCardInput card) {
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('4000000000000002')) {
      return PaymentResult.failure(
        code: 'INSUFFICIENT_FUNDS',
        message: '余额不足，请更换付款方式或联系发卡银行',
      );
    }
    if (digits.startsWith('4000000000000069')) {
      return PaymentResult.failure(
        code: 'EXPIRED_CARD',
        message: '卡片已过期，请更换其他付款方式',
      );
    }
    if (digits.startsWith('4000000000000127')) {
      return PaymentResult.failure(
        code: 'CVV_MISMATCH',
        message: '安全码验证失败，请检查后重新输入',
      );
    }
    return null;
  }

  @override
  Future<bool> verifyPaymentOnServer({
    required PaymentResult result,
    required PaymentSession session,
  }) async {
    if (!result.success) {
      return false;
    }
    await Future<void>.delayed(verifyDelay);
    return result.transactionId.isNotEmpty &&
        session.orderId.isNotEmpty &&
        session.amount > 0;
  }

  String _generateTransactionId(PaymentMethod method) {
    final prefix = switch (method) {
      PaymentMethod.alipay => 'ALI',
      PaymentMethod.wechatPay => 'WX',
      PaymentMethod.applePay => 'APL',
      PaymentMethod.creditCard => 'CC',
    };
    final random = Random.secure().nextInt(99999999).toString().padLeft(8, '0');
    return '$prefix${DateTime.now().millisecondsSinceEpoch}$random';
  }
}

/// Validates checkout input and tokenizes card data in-memory only.
class PaymentValidator {
  PaymentValidator._();

  static String? validateMethodSelection({
    required PaymentMethod? method,
    required double amount,
    required bool applePayAvailable,
    CreditCardInput? card,
  }) {
    if (method == null) {
      return '请选择付款方式';
    }
    if (amount <= 0) {
      return '订单金额无效，请返回重新选择套餐';
    }
    if (method == PaymentMethod.applePay && !applePayAvailable) {
      return '当前设备不支持 Apple Pay';
    }
    if (method == PaymentMethod.creditCard) {
      return validateCreditCard(card);
    }
    return null;
  }

  static String? validateCreditCard(CreditCardInput? card) {
    if (card == null) {
      return '请填写完整的信用卡资料';
    }
    if (card.cardholderName.trim().length < 2) {
      return '请填写持卡人姓名';
    }
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) {
      return '信用卡号码格式不正确';
    }
    if (!_passesLuhnCheck(digits)) {
      return '信用卡号码无效，请检查后重新输入';
    }
    final month = int.tryParse(card.expiryMonth);
    final year = int.tryParse(card.expiryYear);
    if (month == null || month < 1 || month > 12) {
      return '到期月份无效';
    }
    if (year == null || card.expiryYear.length != 2) {
      return '到期年份无效，请使用 MM/YY 格式';
    }
    final now = DateTime.now();
    final fullYear = 2000 + year;
    final expiry = DateTime(fullYear, month + 1);
    if (expiry.isBefore(DateTime(now.year, now.month))) {
      return '卡片已过期，请更换其他付款方式';
    }
    final cvv = card.cvv.trim();
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
      return '安全码 (CVV) 格式不正确';
    }
    return null;
  }

  static String tokenizeCard(CreditCardInput card) {
    final last4 = card.last4;
    final tokenSeed =
        '$last4-${card.expiryMonth}${card.expiryYear}-${DateTime.now().microsecondsSinceEpoch}';
    return 'tok_${tokenSeed.hashCode.abs().toRadixString(16)}';
  }

  static bool _passesLuhnCheck(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = int.parse(digits[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }
}
