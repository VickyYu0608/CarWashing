import 'dart:async';
import 'dart:io';

import 'package:car_washing_app/payment/payment_coordinator.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:car_washing_app/payment/payment_provider_page.dart';
import 'package:car_washing_app/payment/payment_receipt_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef PaymentConfirmedCallback = Future<void> Function({
  required String transactionId,
  required PaymentMethod method,
  String? providerReference,
});

class PaymentCheckoutArgs {
  const PaymentCheckoutArgs({
    required this.orderId,
    required this.storeName,
    required this.packageName,
    required this.amount,
    required this.usedFreeWash,
    required this.payerDisplayName,
    required this.payerPhone,
    required this.onPaymentConfirmed,
  });

  final String orderId;
  final String storeName;
  final String packageName;
  final double amount;
  final bool usedFreeWash;
  final String payerDisplayName;
  final String payerPhone;
  final PaymentConfirmedCallback onPaymentConfirmed;
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({required this.checkout, super.key});

  final PaymentCheckoutArgs checkout;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _coordinator = PaymentCoordinator();
  final _formKey = GlobalKey<FormState>();
  final _cardholderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  PaymentMethod? _selectedMethod;
  PaymentPhase _phase = PaymentPhase.idle;
  String? _errorMessage;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  bool get _isBusy =>
      _phase == PaymentPhase.processing ||
      _phase == PaymentPhase.authorizing ||
      _phase == PaymentPhase.verifying;

  bool get _applePayAvailable => Platform.isIOS;

  PaymentCheckoutArgs get checkout => widget.checkout;

  @override
  void initState() {
    super.initState();
    _coordinator.createSession(
      orderId: checkout.orderId,
      amount: checkout.amount,
      merchantName: checkout.storeName,
      productSummary: checkout.packageName,
      payerDisplayName: checkout.payerDisplayName,
      payerPhone: checkout.payerPhone,
    );
    _remainingTime = _coordinator.activeSession!.remainingTime;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = _coordinator.activeSession;
      if (!mounted || session == null) {
        return;
      }
      if (session.isExpired) {
        setState(() {
          _phase = PaymentPhase.expired;
          _errorMessage = '支付会话已过期，请返回重新下单';
        });
        _countdownTimer?.cancel();
        return;
      }
      setState(() => _remainingTime = session.remainingTime);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _coordinator.reset();
    super.dispose();
  }

  CreditCardInput? _buildCardInput() {
    if (_selectedMethod != PaymentMethod.creditCard) {
      return null;
    }
    final expiryParts = _expiryController.text.split('/');
    return CreditCardInput(
      cardholderName: _cardholderController.text.trim(),
      cardNumber: _cardNumberController.text,
      expiryMonth: expiryParts.isNotEmpty ? expiryParts.first.trim() : '',
      expiryYear: expiryParts.length > 1 ? expiryParts.last.trim() : '',
      cvv: _cvvController.text.trim(),
    );
  }

  Future<bool> _confirmAmountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('确认支付'),
        content: Text(
          '您将向「${checkout.storeName}」支付 '
          '¥${checkout.amount.toStringAsFixed(0)}，'
          '使用${_selectedMethod!.label}。\n\n'
          '请确认金额与收款方无误后再继续。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认继续'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _startCheckout() async {
    if (_isBusy || _phase == PaymentPhase.expired) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    if (_selectedMethod == PaymentMethod.creditCard &&
        !(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _errorMessage = '请填写完整的信用卡资料';
        _phase = PaymentPhase.failed;
      });
      return;
    }

    final card = _buildCardInput();
    final validationError = _coordinator.validateBeforeCheckout(
      method: _selectedMethod,
      applePayAvailable: _applePayAvailable,
      card: card,
    );
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _phase = PaymentPhase.failed;
      });
      return;
    }

    final confirmed = await _confirmAmountDialog();
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _phase = PaymentPhase.processing);

    try {
      final intent = await _coordinator.prepareIntent(_selectedMethod!);
      if (!mounted) {
        return;
      }

      setState(() => _phase = PaymentPhase.authorizing);

      final authorization = await Navigator.of(context).push<ProviderAuthorizationResult>(
        MaterialPageRoute(
          builder: (_) => PaymentProviderPage(
            request: ProviderAuthorizationRequest(
              session: _coordinator.activeSession!,
              intent: intent,
              card: card,
            ),
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (authorization == null || authorization.userCancelled) {
        setState(() {
          _phase = PaymentPhase.cancelled;
          _errorMessage = '您已取消支付';
        });
        return;
      }

      setState(() => _phase = PaymentPhase.verifying);

      final receipt = await _coordinator.executeCheckout(
        intent: intent,
        authorization: authorization,
        card: card,
      );

      if (!mounted || receipt == null) {
        return;
      }

      await checkout.onPaymentConfirmed(
        transactionId: receipt.transactionId,
        method: receipt.method,
        providerReference: receipt.providerReference,
      );

      if (!mounted) {
        return;
      }

      final finished = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentReceiptPage(receipt: receipt),
        ),
      );

      if (!mounted) {
        return;
      }

      if (finished == true) {
        Navigator.of(context).pop(true);
      }
    } on StateError catch (error) {
      setState(() {
        _phase = PaymentPhase.failed;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('收银台'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  _phase == PaymentPhase.expired
                      ? '已过期'
                      : formatPaymentCountdown(_remainingTime),
                  style: TextStyle(
                    color: _remainingTime.inMinutes < 3
                        ? Colors.orange.shade800
                        : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OrderSummaryCard(
              storeName: checkout.storeName,
              packageName: checkout.packageName,
              amount: checkout.amount,
              orderId: checkout.orderId,
              usedFreeWash: checkout.usedFreeWash,
              payerMasked: maskPhoneNumber(checkout.payerPhone),
            ),
            const SizedBox(height: 20),
            Text(
              '选择付款方式',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final method in PaymentMethod.values)
              if (method != PaymentMethod.applePay || _applePayAvailable)
                _PaymentMethodTile(
                  method: method,
                  selected: _selectedMethod == method,
                  enabled: !_isBusy && _phase != PaymentPhase.expired,
                  icon: _methodIcon(method),
                  iconColor: _methodColor(method),
                  subtitleOverride: method == PaymentMethod.applePay && !_applePayAvailable
                      ? '仅 iOS 设备可用'
                      : null,
                  onTap: () => setState(() {
                    _selectedMethod = method;
                    _errorMessage = null;
                  }),
                ),
            if (_selectedMethod == PaymentMethod.creditCard) ...[
              const SizedBox(height: 12),
              _CreditCardForm(
                formKey: _formKey,
                cardholderController: _cardholderController,
                cardNumberController: _cardNumberController,
                expiryController: _expiryController,
                cvvController: _cvvController,
                enabled: !_isBusy,
              ),
              const SizedBox(height: 8),
              Text(
                '正式环境应使用 Stripe / Adyen 等 PCI 认证托管字段，'
                '本 App 不会储存完整卡号或 CVV。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      height: 1.4,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            _PaymentStatusBanner(
              phase: _phase,
              errorMessage: _errorMessage,
            ),
            const SizedBox(height: 8),
            const _SecurityNotice(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isBusy ||
                      _phase == PaymentPhase.expired ||
                      _selectedMethod == null
                  ? null
                  : _startCheckout,
              icon: _isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                switch (_phase) {
                  PaymentPhase.processing => '创建支付单...',
                  PaymentPhase.authorizing => '等待授权...',
                  PaymentPhase.verifying => '校验支付结果...',
                  PaymentPhase.expired => '会话已过期',
                  _ => _selectedMethod == null
                      ? '请选择付款方式'
                      : '确认支付 ¥${checkout.amount.toStringAsFixed(0)}',
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _methodIcon(PaymentMethod method) => switch (method) {
        PaymentMethod.alipay => Icons.account_balance_wallet_outlined,
        PaymentMethod.wechatPay => Icons.chat_bubble_outline,
        PaymentMethod.applePay => Icons.apple,
        PaymentMethod.creditCard => Icons.credit_card_outlined,
      };

  Color _methodColor(PaymentMethod method) => switch (method) {
        PaymentMethod.alipay => const Color(0xff1677ff),
        PaymentMethod.wechatPay => const Color(0xff07c160),
        PaymentMethod.applePay => Colors.black,
        PaymentMethod.creditCard => const Color(0xff6366f1),
      };
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.storeName,
    required this.packageName,
    required this.amount,
    required this.orderId,
    required this.usedFreeWash,
    required this.payerMasked,
  });

  final String storeName;
  final String packageName;
  final double amount;
  final String orderId;
  final bool usedFreeWash;
  final String payerMasked;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              storeName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(packageName),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('应付金额'),
                const Spacer(),
                Text(
                  '¥${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            if (usedFreeWash)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('已使用免费洗车次数'),
              ),
            const SizedBox(height: 8),
            Text('付款账户 $payerMasked'),
            Text('订单号：$orderId', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '支付会话 15 分钟内有效',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.subtitleOverride,
  });

  final PaymentMethod method;
  final bool selected;
  final bool enabled;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: enabled,
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(method.label),
        subtitle: Text(subtitleOverride ?? method.subtitle),
        trailing: Radio<PaymentMethod>(
          value: method,
          groupValue: selected ? method : null,
          onChanged: enabled ? (_) => onTap?.call() : null,
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class _CreditCardForm extends StatelessWidget {
  const _CreditCardForm({
    required this.formKey,
    required this.cardholderController,
    required this.cardNumberController,
    required this.expiryController,
    required this.cvvController,
    required this.enabled,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController cardholderController;
  final TextEditingController cardNumberController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: cardholderController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: '持卡人姓名',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value ?? '').trim().length < 2 ? '请填写持卡人姓名' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cardNumberController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
              _CardNumberFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: '卡号',
              hintText: '4242 4242 4242 4242',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 13 ? '请输入有效的卡号' : null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: '到期日 MM/YY',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value ?? '').length < 5 ? '格式 MM/YY' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: cvvController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => !RegExp(r'^\d{3,4}$').hasMatch(value ?? '')
                      ? '3-4 位数字'
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBanner extends StatelessWidget {
  const _PaymentStatusBanner({
    required this.phase,
    required this.errorMessage,
  });

  final PaymentPhase phase;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (phase == PaymentPhase.idle && errorMessage == null) {
      return const SizedBox.shrink();
    }

    final Color background;
    final IconData icon;
    final String message;

    switch (phase) {
      case PaymentPhase.processing:
      case PaymentPhase.authorizing:
      case PaymentPhase.verifying:
        background = Colors.blue.shade50;
        icon = Icons.hourglass_top_outlined;
        message = switch (phase) {
          PaymentPhase.processing => '正在创建支付单...',
          PaymentPhase.authorizing => '请在支付渠道完成本人确认...',
          PaymentPhase.verifying => '正在校验支付结果...',
          _ => '处理中...',
        };
      case PaymentPhase.expired:
        background = Colors.orange.shade50;
        icon = Icons.timer_off_outlined;
        message = errorMessage ?? '支付会话已过期';
      case PaymentPhase.cancelled:
        background = Colors.grey.shade100;
        icon = Icons.cancel_outlined;
        message = errorMessage ?? '已取消支付';
      case PaymentPhase.failed:
        background = Colors.red.shade50;
        icon = Icons.error_outline;
        message = errorMessage ?? '付款失败';
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      '支付流程：选择方式 → 确认金额 → 跳转支付渠道授权 → 服务端扣款校验 → 支付凭证。'
      '支付宝/微信密码仅在官方 App 内输入，商户端不接触。',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            height: 1.4,
          ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    if (digits.length <= 2) {
      return newValue.copyWith(text: digits);
    }
    final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
