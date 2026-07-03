enum PaymentMethod {
  alipay,
  wechatPay,
  applePay,
  creditCard,
}

enum PaymentPhase {
  idle,
  sessionCreated,
  awaitingProvider,
  authorizing,
  processing,
  verifying,
  success,
  failed,
  cancelled,
  expired,
}

enum PaymentSessionStatus {
  created,
  awaitingUserAction,
  processing,
  succeeded,
  failed,
  cancelled,
  expired,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.alipay => 'Alipay 支付宝',
        PaymentMethod.wechatPay => 'WeChat Pay 微信支付',
        PaymentMethod.applePay => 'Apple Pay',
        PaymentMethod.creditCard => '信用卡 Credit Card',
      };

  String get subtitle => switch (this) {
        PaymentMethod.alipay => '跳转支付宝 App 由本人账户确认支付',
        PaymentMethod.wechatPay => '跳转微信 App 由本人账户确认支付',
        PaymentMethod.applePay => 'Face ID / Touch ID 确认支付',
        PaymentMethod.creditCard => 'Visa · Mastercard · UnionPay',
      };

  String get providerName => switch (this) {
        PaymentMethod.alipay => '支付宝',
        PaymentMethod.wechatPay => '微信支付',
        PaymentMethod.applePay => 'Apple Pay',
        PaymentMethod.creditCard => '发卡银行',
      };
}

class PaymentSession {
  PaymentSession({
    required this.sessionId,
    required this.orderId,
    required this.amount,
    required this.merchantName,
    required this.productSummary,
    required this.payerDisplayName,
    required this.payerPhoneMasked,
    required this.createdAt,
    required this.expiresAt,
    this.status = PaymentSessionStatus.created,
    this.selectedMethod,
    this.idempotencyKey,
  });

  final String sessionId;
  final String orderId;
  final double amount;
  final String merchantName;
  final String productSummary;
  final String payerDisplayName;
  final String payerPhoneMasked;
  final DateTime createdAt;
  final DateTime expiresAt;
  PaymentSessionStatus status;
  PaymentMethod? selectedMethod;
  String? idempotencyKey;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());
}

class PaymentIntent {
  const PaymentIntent({
    required this.intentId,
    required this.sessionId,
    required this.method,
    required this.amount,
    required this.merchantReference,
  });

  final String intentId;
  final String sessionId;
  final PaymentMethod method;
  final double amount;
  final String merchantReference;
}

class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.transactionId,
    this.errorCode,
    this.errorMessage,
    this.paymentMethod,
    this.authorizedAt,
    this.capturedAt,
    this.providerReference,
  });

  final bool success;
  final String transactionId;
  final String? errorCode;
  final String? errorMessage;
  final PaymentMethod? paymentMethod;
  final DateTime? authorizedAt;
  final DateTime? capturedAt;
  final String? providerReference;

  factory PaymentResult.success({
    required String transactionId,
    required PaymentMethod method,
    required String providerReference,
    required DateTime authorizedAt,
    required DateTime capturedAt,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      paymentMethod: method,
      providerReference: providerReference,
      authorizedAt: authorizedAt,
      capturedAt: capturedAt,
    );
  }

  factory PaymentResult.failure({
    required String code,
    required String message,
  }) {
    return PaymentResult(
      success: false,
      transactionId: '',
      errorCode: code,
      errorMessage: message,
    );
  }
}

class PaymentReceipt {
  const PaymentReceipt({
    required this.transactionId,
    required this.providerReference,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.merchantName,
    required this.productSummary,
    required this.paidAt,
  });

  final String transactionId;
  final String providerReference;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final String merchantName;
  final String productSummary;
  final DateTime paidAt;
}

class CreditCardInput {
  const CreditCardInput({
    required this.cardholderName,
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  final String cardholderName;
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;

  String get last4 {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
  }
}

class ProviderAuthorizationRequest {
  const ProviderAuthorizationRequest({
    required this.session,
    required this.intent,
    this.card,
  });

  final PaymentSession session;
  final PaymentIntent intent;
  final CreditCardInput? card;
}

class ProviderAuthorizationResult {
  const ProviderAuthorizationResult({
    required this.approved,
    this.providerReference,
    this.errorMessage,
    this.userCancelled = false,
  });

  final bool approved;
  final String? providerReference;
  final String? errorMessage;
  final bool userCancelled;

  factory ProviderAuthorizationResult.approved(String providerReference) =>
      ProviderAuthorizationResult(
        approved: true,
        providerReference: providerReference,
      );

  factory ProviderAuthorizationResult.rejected(String message) =>
      ProviderAuthorizationResult(approved: false, errorMessage: message);

  factory ProviderAuthorizationResult.cancelled() =>
      const ProviderAuthorizationResult(
        approved: false,
        userCancelled: true,
        errorMessage: '您已取消支付',
      );
}

String maskPhoneNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) {
    return phone;
  }
  final prefix = digits.substring(0, 3);
  final suffix = digits.substring(digits.length - 4);
  return '$prefix****$suffix';
}

String formatPaymentCountdown(Duration remaining) {
  if (remaining.isNegative) {
    return '00:00';
  }
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
