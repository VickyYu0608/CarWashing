import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// In-app cashier that mirrors WeChat Pay's amount + password screen.
/// Used when merchant prepay is not configured, or as a fallback if SDK pay
/// cannot be launched.
class WeChatPayCashierPage extends StatefulWidget {
  const WeChatPayCashierPage({
    required this.session,
    super.key,
  });

  final PaymentSession session;

  @override
  State<WeChatPayCashierPage> createState() => _WeChatPayCashierPageState();
}

class _WeChatPayCashierPageState extends State<WeChatPayCashierPage> {
  static const _weChatGreen = Color(0xff07c160);

  final List<String> _digits = [];
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _submitPassword() async {
    if (_digits.length < 6 || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _appendDigit(String digit) {
    if (_submitting || _digits.length >= 6) {
      return;
    }
    setState(() {
      _digits.add(digit);
      _errorMessage = null;
    });
    HapticFeedback.selectionClick();
    if (_digits.length == 6) {
      _submitPassword();
    }
  }

  void _deleteDigit() {
    if (_submitting || _digits.isEmpty) {
      return;
    }
    setState(() => _digits.removeLast());
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _weChatGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Text(s.paymentMethodWechat),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              children: [
                Text(
                  widget.session.merchantName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '¥${widget.session.amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.session.productSummary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45),
                ),
                const SizedBox(height: 28),
                Text(
                  s.enterPayPassword,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 6; i++)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _digits.length
                              ? Colors.black87
                              : Colors.black12,
                        ),
                      ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (_submitting) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator(color: _weChatGreen)),
                ],
              ],
            ),
          ),
          _NumericKeypad(
            enabled: !_submitting,
            onDigit: _appendDigit,
            onDelete: _deleteDigit,
          ),
        ],
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    Widget keyButton(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffededed)),
              ),
              child: child ??
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> keys) => Row(children: keys);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          row([
            keyButton('1', onTap: () => onDigit('1')),
            keyButton('2', onTap: () => onDigit('2')),
            keyButton('3', onTap: () => onDigit('3')),
          ]),
          row([
            keyButton('4', onTap: () => onDigit('4')),
            keyButton('5', onTap: () => onDigit('5')),
            keyButton('6', onTap: () => onDigit('6')),
          ]),
          row([
            keyButton('7', onTap: () => onDigit('7')),
            keyButton('8', onTap: () => onDigit('8')),
            keyButton('9', onTap: () => onDigit('9')),
          ]),
          row([
            const Expanded(child: SizedBox()),
            keyButton('0', onTap: () => onDigit('0')),
            keyButton(
              '',
              onTap: onDelete,
              child: const Icon(Icons.backspace_outlined),
            ),
          ]),
        ],
      ),
    );
  }
}
