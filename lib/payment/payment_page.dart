import 'dart:async';
import 'dart:io';

import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/payment/api_payment_gateway.dart';
import 'package:car_washing_app/payment/payment_coordinator.dart';
import 'package:car_washing_app/payment/payment_models.dart';
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
  final _coordinator = PaymentCoordinator(gateway: resolvePaymentGateway());
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
          _errorMessage = AppStrings.current.paymentSessionExpiredReturn;
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
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.confirmPayment),
        content: Text(
          s.paymentConfirmDialogBody(
            checkout.storeName,
            checkout.amount,
            _selectedMethod!.label,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancelBtn),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.confirmContinue),
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
        _errorMessage = context.s.fillCompleteCardInfo;
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

    // Payment integration is still in development — treat checkout as successful
    // after the user confirms amount and method.
    setState(() => _phase = PaymentPhase.verifying);
    try {
      final bypassRef =
          'demo_bypass_${_selectedMethod!.name}_${DateTime.now().millisecondsSinceEpoch}';
      await checkout.onPaymentConfirmed(
        transactionId: bypassRef,
        method: _selectedMethod!,
        providerReference: bypassRef,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      setState(() {
        _phase = PaymentPhase.failed;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PopScope(
      canPop: !_isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.cashierTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  _phase == PaymentPhase.expired
                      ? s.expiredLabel
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
              s.selectPaymentMethod,
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
                      ? s.iosOnly
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
                s.pciComplianceNote,
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
                  PaymentPhase.processing => s.creatingPayment,
                  PaymentPhase.authorizing => s.awaitingAuthorization,
                  PaymentPhase.verifying => s.verifyingPayment,
                  PaymentPhase.expired => s.sessionExpired,
                  _ => _selectedMethod == null
                      ? s.selectMethodFirst
                      : s.confirmPayAmount(checkout.amount),
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
    final s = context.s;
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
                Text(s.amountDue),
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(s.usedFreeWashCredits),
              ),
            const SizedBox(height: 8),
            Text(s.payerAccount(payerMasked)),
            Text(s.orderIdLine(orderId), style: Theme.of(context).textTheme.bodySmall),
            Text(
              s.sessionValid15Min,
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
          backgroundColor: iconColor.withValues(alpha: 0.12),
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
    final s = context.s;
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: cardholderController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.cardholderName,
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                (value ?? '').trim().length < 2 ? s.enterCardholderName : null,
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
            decoration: InputDecoration(
              labelText: s.cardNumber,
              hintText: '4242 4242 4242 4242',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 13 ? s.invalidCardNumber : null;
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
                  decoration: InputDecoration(
                    labelText: s.expiryDate,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value ?? '').length < 5 ? s.expiryFormat : null,
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
                      ? s.cvvInvalid
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
    final s = context.s;
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
          PaymentPhase.processing => s.creatingPaymentBanner,
          PaymentPhase.authorizing => s.authInProviderBanner,
          PaymentPhase.verifying => s.verifyingBanner,
          _ => s.processingGeneric,
        };
      case PaymentPhase.expired:
        background = Colors.orange.shade50;
        icon = Icons.timer_off_outlined;
        message = errorMessage ?? s.sessionExpired;
      case PaymentPhase.cancelled:
        background = Colors.grey.shade100;
        icon = Icons.cancel_outlined;
        message = errorMessage ?? s.paymentCancelled;
      case PaymentPhase.failed:
        background = Colors.red.shade50;
        icon = Icons.error_outline;
        message = errorMessage ?? s.paymentFailed;
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
      context.s.paymentFlowNotice,
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
