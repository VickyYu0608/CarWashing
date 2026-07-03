import 'dart:async';
import 'dart:io';

import 'package:car_washing_app/payment/payment_external_launcher.dart';
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

class _PaymentProviderPageState extends State<PaymentProviderPage>
    with WidgetsBindingObserver {
  bool _redirecting = true;
  bool _externalLaunched = false;
  bool _returnedFromExternal = false;
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

  bool get _usesExternalApp => method == PaymentMethod.alipay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_usesWeChatPay) {
      _startWeChatPaymentFlow();
    } else if (_usesExternalApp) {
      _startExternalPaymentFlow();
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
      _errorMessage = result.errorMessage ?? '微信支付失败';
    });
  }

  Future<void> _startExternalPaymentFlow() async {
    _redirectTimer?.cancel();
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_redirectSeconds <= 1) {
        timer.cancel();
        _openExternalPaymentApp();
        return;
      }
      setState(() => _redirectSeconds -= 1);
    });
  }

  Future<void> _openExternalPaymentApp() async {
    if (_isLaunching) {
      return;
    }
    setState(() {
      _isLaunching = true;
      _errorMessage = null;
    });

    final result = await PaymentExternalLauncher.launch(
      method: method,
      session: session,
    );

    if (!mounted) {
      return;
    }

    if (!result.launched) {
      setState(() {
        _redirecting = false;
        _isLaunching = false;
        _errorMessage = result.errorMessage;
      });
      return;
    }

    setState(() {
      _redirecting = false;
      _externalLaunched = true;
      _isLaunching = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_usesExternalApp || !_externalLaunched || _isSubmitting) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      setState(() => _returnedFromExternal = true);
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _confirmExternalPayment() async {
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
    if (_redirecting && (_usesExternalApp || _usesWeChatPay)) {
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

    if (_usesExternalApp) {
      return _ExternalPaymentReturnView(
        method: method,
        session: session,
        returnedFromExternal: _returnedFromExternal,
        externalLaunched: _externalLaunched,
        isSubmitting: _isSubmitting,
        isLaunching: _isLaunching,
        errorMessage: _errorMessage,
        onOpenApp: _openExternalPaymentApp,
        onConfirmPaid: _confirmExternalPayment,
        onCancel: () => Navigator.of(context).pop(
          ProviderAuthorizationResult.cancelled(),
        ),
        onInstallApp: () => PaymentExternalLauncher.openStoreListing(method),
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
        PaymentMethod.creditCard =>
          '确认使用尾号 ${request.card?.last4 ?? '****'} 卡片支付 ¥${session.amount.toStringAsFixed(0)}',
        _ => '',
      };

  String get _securityHint => switch (method) {
        PaymentMethod.applePay => '生物识别验证由 Apple Pay 安全模块处理。',
        PaymentMethod.creditCard =>
          '卡片信息已加密处理，本 App 不会储存完整卡号或 CVV。',
        _ => '',
      };

  Color get _providerBackground => switch (method) {
        PaymentMethod.applePay => Colors.black,
        PaymentMethod.creditCard => const Color(0xff1e3a5f),
        _ => Colors.black,
      };

  Color get _providerAccent => _providerBackground;

  String get _primaryButtonLabel => switch (method) {
        PaymentMethod.applePay => '通过 Face ID 支付',
        PaymentMethod.creditCard => '确认信用卡支付',
        _ => '确认支付',
      };
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
    return Scaffold(
      backgroundColor: const Color(0xff07c160),
      appBar: AppBar(
        backgroundColor: const Color(0xff07c160),
        foregroundColor: Colors.white,
        title: const Text('微信支付'),
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
                : const Text('重试微信支付'),
          ),
          TextButton(
            onPressed: isRetrying ? null : onCancel,
            child: Text(
              '取消支付',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalPaymentReturnView extends StatelessWidget {
  const _ExternalPaymentReturnView({
    required this.method,
    required this.session,
    required this.returnedFromExternal,
    required this.externalLaunched,
    required this.isSubmitting,
    required this.isLaunching,
    required this.onOpenApp,
    required this.onConfirmPaid,
    required this.onCancel,
    required this.onInstallApp,
    this.errorMessage,
  });

  final PaymentMethod method;
  final PaymentSession session;
  final bool returnedFromExternal;
  final bool externalLaunched;
  final bool isSubmitting;
  final bool isLaunching;
  final String? errorMessage;
  final VoidCallback onOpenApp;
  final VoidCallback onConfirmPaid;
  final VoidCallback onCancel;
  final Future<bool> Function() onInstallApp;

  Color get _color => switch (method) {
        PaymentMethod.alipay => const Color(0xff1677ff),
        PaymentMethod.wechatPay => const Color(0xff07c160),
        _ => Colors.black,
      };

  @override
  Widget build(BuildContext context) {
    final waitingInExternalApp = externalLaunched && !returnedFromExternal;

    return PopScope(
      canPop: !isSubmitting,
      child: Scaffold(
        backgroundColor: _color,
        appBar: AppBar(
          backgroundColor: _color,
          foregroundColor: Colors.white,
          title: Text('${method.providerName} · 安全支付'),
          leading: isSubmitting
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCancel,
                ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProviderPaymentCard(
              method: method,
              session: session,
            ),
            const SizedBox(height: 20),
            Icon(
              waitingInExternalApp ? Icons.open_in_new : Icons.check_circle_outline,
              color: Colors.white,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              waitingInExternalApp
                  ? '正在${method.providerName}中完成支付'
                  : '请确认是否已在${method.providerName}完成支付',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              waitingInExternalApp
                  ? '支付密码 / 指纹请在${method.providerName} App 内完成。\n完成后请返回本 App 继续。'
                  : '如未完成支付，可重新打开${method.providerName}。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 28),
            if (!externalLaunched || errorMessage != null) ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _color,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: isLaunching ? null : onOpenApp,
                child: isLaunching
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('打开${method.providerName}'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => onInstallApp(),
                child: Text('去安装${method.providerName}'),
              ),
            ] else ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _color,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: isSubmitting || !returnedFromExternal ? null : onConfirmPaid,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(returnedFromExternal ? '我已在${method.providerName}完成支付' : '返回 App 后可确认'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: isLaunching || isSubmitting ? null : onOpenApp,
                child: Text('重新打开${method.providerName}'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: isSubmitting ? null : onCancel,
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
                '即将打开${method.providerName} App\n请在${method.providerName}内完成支付',
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
