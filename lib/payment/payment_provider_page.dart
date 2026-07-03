import 'dart:async';
import 'dart:io';

import 'package:car_washing_app/payment/payment_gateway.dart';
import 'package:car_washing_app/payment/payment_models.dart';
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
  String? _errorMessage;
  int _redirectSeconds = 3;
  Timer? _redirectTimer;

  ProviderAuthorizationRequest get request => widget.request;
  PaymentSession get session => request.session;
  PaymentMethod get method => request.intent.method;

  bool get _usesExternalRedirect =>
      method == PaymentMethod.alipay ||
      method == PaymentMethod.wechatPay ||
      method == PaymentMethod.creditCard;

  @override
  void initState() {
    super.initState();
    if (_usesExternalRedirect) {
      _startRedirectCountdown();
    } else {
      _redirecting = false;
    }
  }

  void _startRedirectCountdown() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_redirectSeconds <= 1) {
        timer.cancel();
        setState(() => _redirecting = false);
        return;
      }
      setState(() => _redirectSeconds -= 1);
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
        _errorMessage = result.errorMessage ?? '授权失败';
      });
      return;
    }

    Navigator.of(context).pop(result);
  }

  Future<void> _confirmPayment() async {
    if (!_userConfirmed) {
      setState(() => _errorMessage = '请确认付款信息后再继续');
      return;
    }
    await _completeAuthorization(userConfirmedInProvider: true);
  }

  Future<void> _confirmApplePay() async {
    if (!_userConfirmed) {
      setState(() => _errorMessage = '请确认 Apple Pay 付款信息');
      return;
    }

    setState(() => _isSubmitting = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Apple Pay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Platform.isIOS ? Icons.face : Icons.fingerprint,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              '请使用 Face ID / Touch ID 验证\n确认支付 ¥${session.amount.toStringAsFixed(0)}',
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
    if (_redirecting && _usesExternalRedirect) {
      return _RedirectSplash(
        method: method,
        seconds: _redirectSeconds,
        amount: session.amount,
      );
    }

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: _providerBackground,
        appBar: AppBar(
          backgroundColor: _providerBackground,
          foregroundColor: Colors.white,
          title: Text('${method.providerName} · 安全支付'),
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
              style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.4),
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
                '取消支付',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _confirmLabel => switch (method) {
        PaymentMethod.alipay =>
          '确认使用本人支付宝账户支付 ¥${session.amount.toStringAsFixed(0)}',
        PaymentMethod.wechatPay =>
          '确认使用本人微信账户支付 ¥${session.amount.toStringAsFixed(0)}',
        PaymentMethod.applePay =>
          '使用 Apple Pay 支付 ¥${session.amount.toStringAsFixed(0)}',
        PaymentMethod.creditCard =>
          '确认使用尾号 ${request.card?.last4 ?? '****'} 卡片支付 ¥${session.amount.toStringAsFixed(0)}',
      };

  String get _securityHint => switch (method) {
        PaymentMethod.alipay || PaymentMethod.wechatPay =>
          '支付密码 / 指纹请在${method.providerName} App 内完成，本商户不会收集您的支付密码。',
        PaymentMethod.applePay => '生物识别验证由 Apple Pay 安全模块处理。',
        PaymentMethod.creditCard =>
          '卡片信息已加密处理，本 App 不会储存完整卡号或 CVV。',
      };

  Color get _providerBackground => switch (method) {
        PaymentMethod.alipay => const Color(0xff1677ff),
        PaymentMethod.wechatPay => const Color(0xff07c160),
        PaymentMethod.applePay => Colors.black,
        PaymentMethod.creditCard => const Color(0xff1e3a5f),
      };

  Color get _providerAccent => _providerBackground;

  String get _primaryButtonLabel => switch (method) {
        PaymentMethod.alipay => '在支付宝确认支付',
        PaymentMethod.wechatPay => '在微信确认支付',
        PaymentMethod.applePay => '通过 Face ID 支付',
        PaymentMethod.creditCard => '确认信用卡支付',
      };
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
                '正在跳转${method.providerName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¥${amount.toStringAsFixed(0)} · $seconds 秒',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _redirectMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.5),
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

  String get _redirectMessage => switch (method) {
        PaymentMethod.creditCard =>
          '正在连接发卡银行安全通道\n请在银行页面确认付款',
        _ => '请在${method.providerName} App 内确认付款\n商户不会要求您在本 App 输入支付密码',
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
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收款方', style: Theme.of(context).textTheme.bodySmall),
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
                const Text('支付金额'),
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
            Text('付款账户', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${session.payerDisplayName} · ${session.payerPhoneMasked}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (card != null) ...[
              const SizedBox(height: 8),
              Text('卡片 · ${card!.cardholderName} · 尾号 ${card!.last4}'),
            ],
            const SizedBox(height: 8),
            Text(
              '订单号 ${session.orderId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
