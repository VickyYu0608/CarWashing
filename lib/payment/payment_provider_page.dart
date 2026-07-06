import 'dart:async';
import 'dart:io';

import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/payment/alipay_pay_service.dart';
import 'package:car_washing_app/payment/payment_gateway.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:car_washing_app/payment/wechat_pay_service.dart';
import 'package:flutter/material.dart';

/// User authorizes payment inside the payment provider environment
/// (Alipay / WeChat app redirect, Apple Pay sheet, or card confirmation).
class PaymentProviderPage extends StatefulWidget {
  const PaymentProviderPage({
    required this.request,
    super.key,
  });

  final ProviderAuthorizationRequest request;

  @override
  State<PaymentProviderPage> createState() => _PaymentProviderPageState();
}

class _PaymentProviderPageState extends State<PaymentProviderPage> {
  bool _redirecting = true;
  bool _userConfirmed = false;
  bool _isSubmitting = false;
  bool _isLaunching = false;
  String? _errorMessage;
  int _redirectSeconds = 2;
  Timer? _redirectTimer;

  ProviderAuthorizationRequest get request => widget.request;
  PaymentSession get session => request.session;
  PaymentMethod get method => request.intent.method;

  bool get _usesWeChatPay => method == PaymentMethod.wechatPay;
  bool get _usesAlipayPay => method == PaymentMethod.alipay;

  @override
  void initState() {
    super.initState();
    if (_usesWeChatPay) {
      _startWeChatPaymentFlow();
    } else if (_usesAlipayPay) {
      _startAlipayPaymentFlow();
    } else {
      _redirecting = false;
    }
  }

  Future<void> _startWeChatPaymentFlow() async {
    _redirectTimer?.cancel();
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_redirectSeconds <= 1) {
        timer.cancel();
        _launchWeChatPayment();
        return;
      }
      setState(() => _redirectSeconds -= 1);
    });
  }

  Future<void> _launchWeChatPayment() async {
    if (_isLaunching) {
      return;
    }
    setState(() {
      _redirecting = false;
      _isLaunching = true;
      _errorMessage = null;
    });

    final result = await WeChatPayService.instance.pay(
      context: context,
      session: session,
      intent: request.intent,
    );

    if (!mounted) {
      return;
    }

    if (result.success && result.providerReference != null) {
      Navigator.of(context).pop(
        ProviderAuthorizationResult.approved(result.providerReference!),
      );
      return;
    }

    if (result.userCancelled) {
      Navigator.of(context).pop(ProviderAuthorizationResult.cancelled());
      return;
    }

    setState(() {
      _isLaunching = false;
      _errorMessage = result.errorMessage ?? AppStrings.current.wechatPayFailed;
    });
  }

  Future<void> _startAlipayPaymentFlow() async {
    _redirectTimer?.cancel();
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_redirectSeconds <= 1) {
        timer.cancel();
        _launchAlipayPayment();
        return;
      }
      setState(() => _redirectSeconds -= 1);
    });
  }

  Future<void> _launchAlipayPayment() async {
    if (_isLaunching) {
      return;
    }
    setState(() {
      _redirecting = false;
      _isLaunching = true;
      _errorMessage = null;
    });

    final result = await AlipayPayService.instance.pay(
      context: context,
      session: session,
      intent: request.intent,
    );

    if (!mounted) {
      return;
    }

    if (result.success && result.providerReference != null) {
      Navigator.of(context).pop(
        ProviderAuthorizationResult.approved(result.providerReference!),
      );
      return;
    }

    if (result.userCancelled) {
      Navigator.of(context).pop(ProviderAuthorizationResult.cancelled());
      return;
    }

    setState(() {
      _isLaunching = false;
      _errorMessage = result.errorMessage ?? AppStrings.current.alipayPayFailed;
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _completeAuthorization({
    required bool userConfirmedInProvider,
    bool biometricConfirmed = false,
  }) async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await SandboxPaymentGateway.instance.authorizeWithProvider(
      request: request,
      userConfirmedInProvider: userConfirmedInProvider,
      biometricConfirmed: biometricConfirmed,
    );

    if (!mounted) {
      return;
    }

    if (result.userCancelled) {
      Navigator.of(context).pop(result);
      return;
    }

    if (!result.approved) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.errorMessage ?? AppStrings.current.authFailed;
      });
      return;
    }

    Navigator.of(context).pop(result);
  }

  Future<void> _confirmPayment() async {
    if (!_userConfirmed) {
      setState(() => _errorMessage = context.s.confirmPaymentInfo);
      return;
    }
    await _completeAuthorization(userConfirmedInProvider: true);
  }

  Future<void> _confirmApplePay() async {
    if (!_userConfirmed) {
      setState(() => _errorMessage = context.s.confirmApplePayInfo);
      return;
    }

    setState(() => _isSubmitting = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.s.paymentMethodApplePay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Platform.isIOS ? Icons.face : Icons.fingerprint,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              context.s.applePayBiometricVerify(session.amount),
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    await _completeAuthorization(
      userConfirmedInProvider: true,
      biometricConfirmed: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_redirecting && (_usesWeChatPay || _usesAlipayPay)) {
      return _RedirectSplash(
        method: method,
        seconds: _redirectSeconds,
        amount: session.amount,
      );
    }

    if (_usesWeChatPay && _errorMessage != null) {
      return _WeChatPayErrorView(
        session: session,
        errorMessage: _errorMessage!,
        isRetrying: _isLaunching,
        onRetry: _launchWeChatPayment,
        onCancel: () => Navigator.of(context).pop(
          ProviderAuthorizationResult.cancelled(),
        ),
      );
    }

    if (_usesAlipayPay && _errorMessage != null) {
      return _AlipayPayErrorView(
        session: session,
        errorMessage: _errorMessage!,
        isRetrying: _isLaunching,
        onRetry: _launchAlipayPayment,
        onCancel: () => Navigator.of(context).pop(
          ProviderAuthorizationResult.cancelled(),
        ),
      );
    }

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: _providerBackground,
        appBar: AppBar(
          backgroundColor: _providerBackground,
          foregroundColor: Colors.white,
          title: Text(s.securePayment(method.providerName)),
          leading: _isSubmitting
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(
                    ProviderAuthorizationResult.cancelled(),
                  ),
                ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProviderPaymentCard(
              method: method,
              session: session,
              card: request.card,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _userConfirmed,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _userConfirmed = value ?? false),
              title: Text(
                _confirmLabel,
                style: const TextStyle(color: Colors.white),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              checkColor: _providerAccent,
              activeColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _securityHint,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), height: 1.4),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _providerAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _isSubmitting
                  ? null
                  : method == PaymentMethod.applePay
                      ? _confirmApplePay
                      : _confirmPayment,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_primaryButtonLabel),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(
                        ProviderAuthorizationResult.cancelled(),
                      ),
              child: Text(
                s.cancelPayment,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _confirmLabel {
    final s = AppStrings.current;
    return switch (method) {
      PaymentMethod.creditCard => s.confirmCardPay(
          request.card?.last4 ?? '****',
          session.amount,
        ),
      _ => '',
    };
  }

  String get _securityHint {
    final s = AppStrings.current;
    return switch (method) {
      PaymentMethod.applePay => s.applePaySecurityHint,
      PaymentMethod.creditCard => s.cardEncryptedHint,
      _ => '',
    };
  }

  Color get _providerBackground => switch (method) {
        PaymentMethod.applePay => Colors.black,
        PaymentMethod.creditCard => const Color(0xff1e3a5f),
        _ => Colors.black,
      };

  Color get _providerAccent => _providerBackground;

  String get _primaryButtonLabel {
    final s = AppStrings.current;
    return switch (method) {
      PaymentMethod.applePay => s.payWithFaceId,
      PaymentMethod.creditCard => s.confirmCreditCardPay,
      _ => s.confirmPayment,
    };
  }
}

class _WeChatPayErrorView extends StatelessWidget {
  const _WeChatPayErrorView({
    required this.session,
    required this.errorMessage,
    required this.isRetrying,
    required this.onRetry,
    required this.onCancel,
  });

  final PaymentSession session;
  final String errorMessage;
  final bool isRetrying;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: const Color(0xff07c160),
      appBar: AppBar(
        backgroundColor: const Color(0xff07c160),
        foregroundColor: Colors.white,
        title: Text(s.paymentMethodWechat),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProviderPaymentCard(
            method: PaymentMethod.wechatPay,
            session: session,
          ),
          const SizedBox(height: 20),
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff07c160),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: isRetrying ? null : onRetry,
            child: isRetrying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.retryWechatPay),
          ),
          TextButton(
            onPressed: isRetrying ? null : onCancel,
            child: Text(
              s.cancelPayment,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlipayPayErrorView extends StatelessWidget {
  const _AlipayPayErrorView({
    required this.session,
    required this.errorMessage,
    required this.isRetrying,
    required this.onRetry,
    required this.onCancel,
  });

  final PaymentSession session;
  final String errorMessage;
  final bool isRetrying;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: const Color(0xff1677ff),
      appBar: AppBar(
        backgroundColor: const Color(0xff1677ff),
        foregroundColor: Colors.white,
        title: Text(s.paymentMethodAlipay),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProviderPaymentCard(
            method: PaymentMethod.alipay,
            session: session,
          ),
          const SizedBox(height: 20),
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff1677ff),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: isRetrying ? null : onRetry,
            child: isRetrying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.retryAlipayPay),
          ),
          TextButton(
            onPressed: isRetrying ? null : onCancel,
            child: Text(
              s.cancelPayment,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedirectSplash extends StatelessWidget {
  const _RedirectSplash({
    required this.method,
    required this.seconds,
    required this.amount,
  });

  final PaymentMethod method;
  final int seconds;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final color = switch (method) {
      PaymentMethod.alipay => const Color(0xff1677ff),
      PaymentMethod.wechatPay => const Color(0xff07c160),
      PaymentMethod.creditCard => const Color(0xff1e3a5f),
      PaymentMethod.applePay => Colors.black,
    };

    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_redirectIcon, size: 72, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                s.redirectingTo(method.providerName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.redirectCountdown(amount, seconds),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                s.openingCashier(method.providerName),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _redirectIcon => switch (method) {
        PaymentMethod.alipay => Icons.account_balance_wallet,
        PaymentMethod.wechatPay => Icons.chat_bubble,
        PaymentMethod.creditCard => Icons.credit_card,
        PaymentMethod.applePay => Icons.apple,
      };
}

class _ProviderPaymentCard extends StatelessWidget {
  const _ProviderPaymentCard({
    required this.method,
    required this.session,
    this.card,
  });

  final PaymentMethod method;
  final PaymentSession session;
  final CreditCardInput? card;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.payeeLabel, style: Theme.of(context).textTheme.bodySmall),
            Text(
              session.merchantName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(session.productSummary),
            const Divider(height: 24),
            Row(
              children: [
                Text(s.paymentAmount),
                const Spacer(),
                Text(
                  '¥${session.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(s.payerAccountLabel, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${session.payerDisplayName} · ${session.payerPhoneMasked}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (card != null) ...[
              const SizedBox(height: 8),
              Text(s.cardLine(card!.cardholderName, card!.last4)),
            ],
            const SizedBox(height: 8),
            Text(
              s.orderIdShort(session.orderId),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
