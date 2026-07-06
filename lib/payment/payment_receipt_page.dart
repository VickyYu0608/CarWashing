import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:flutter/material.dart';

class PaymentReceiptPage extends StatelessWidget {
  const PaymentReceiptPage({required this.receipt, super.key});

  final PaymentReceipt receipt;

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.paymentSuccessTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 72),
          const SizedBox(height: 12),
          Text(
            s.paySuccess,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${receipt.amount.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade700,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ReceiptRow(
                    label: s.receiptPaymentMethod,
                    value: receipt.method.label,
                  ),
                  _ReceiptRow(
                    label: s.receiptMerchant,
                    value: receipt.merchantName,
                  ),
                  _ReceiptRow(
                    label: s.receiptProduct,
                    value: receipt.productSummary,
                  ),
                  _ReceiptRow(
                    label: s.receiptOrderId,
                    value: receipt.orderId,
                  ),
                  _ReceiptRow(
                    label: s.receiptTransactionId,
                    value: receipt.transactionId,
                  ),
                  _ReceiptRow(
                    label: s.receiptProviderRef,
                    value: receipt.providerReference,
                  ),
                  _ReceiptRow(
                    label: s.receiptPaidAt,
                    value: _formatTime(receipt.paidAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.receiptKeepTransactionId,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.completeAndStartWash),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
