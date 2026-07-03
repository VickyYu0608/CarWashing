import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/payment/payment_gateway.dart';
import 'package:car_washing_app/payment/payment_models.dart';

/// Uses the backend to confirm payments when [ApiClient.useBackend] is enabled.
class ApiPaymentGateway implements PaymentGateway {
  ApiPaymentGateway._();

  static final ApiPaymentGateway instance = ApiPaymentGateway._();
  final _sandbox = SandboxPaymentGateway.instance;

  @override
  Future<PaymentIntent> createPaymentIntent({
    required PaymentSession session,
    required PaymentMethod method,
  }) =>
      _sandbox.createPaymentIntent(session: session, method: method);

  @override
  Future<ProviderAuthorizationResult> authorizeWithProvider({
    required ProviderAuthorizationRequest request,
    required bool userConfirmedInProvider,
    bool biometricConfirmed = false,
  }) =>
      _sandbox.authorizeWithProvider(
        request: request,
        userConfirmedInProvider: userConfirmedInProvider,
        biometricConfirmed: biometricConfirmed,
      );

  @override
  Future<PaymentResult> capturePayment({
    required PaymentSession session,
    required PaymentIntent intent,
    required String providerReference,
    CreditCardInput? card,
  }) async {
    if (!ApiClient.useBackend ||
        intent.method == PaymentMethod.creditCard ||
        intent.method == PaymentMethod.applePay) {
      return _sandbox.capturePayment(
        session: session,
        intent: intent,
        providerReference: providerReference,
        card: card,
      );
    }

    try {
      final confirmed = await ApiClient.confirmPayment(
        orderId: session.orderId,
        intentId: intent.intentId,
        method: intent.method,
        providerReference: providerReference,
        amount: session.amount,
      );
      if (confirmed['verified'] != true) {
        return PaymentResult.failure(
          code: 'VERIFY_FAILED',
          message: '支付结果校验失败',
        );
      }
      return PaymentResult.success(
        transactionId: confirmed['transaction_id']?.toString() ?? providerReference,
        method: intent.method,
        providerReference:
            confirmed['provider_reference']?.toString() ?? providerReference,
        authorizedAt: DateTime.now(),
        capturedAt: DateTime.tryParse(
              confirmed['paid_at']?.toString() ?? '',
            ) ??
            DateTime.now(),
      );
    } on ApiException catch (exception) {
      return PaymentResult.failure(
        code: 'PAYMENT_CONFIRM_FAILED',
        message: exception.message,
      );
    } on ApiConnectionException {
      return _sandbox.capturePayment(
        session: session,
        intent: intent,
        providerReference: providerReference,
        card: card,
      );
    }
  }

  @override
  Future<bool> verifyPaymentOnServer({
    required PaymentResult result,
    required PaymentSession session,
  }) async {
    if (!ApiClient.useBackend) {
      return _sandbox.verifyPaymentOnServer(result: result, session: session);
    }
    return result.success;
  }
}

PaymentGateway resolvePaymentGateway() {
  if (ApiClient.useBackend) {
    return ApiPaymentGateway.instance;
  }
  return SandboxPaymentGateway.instance;
}
