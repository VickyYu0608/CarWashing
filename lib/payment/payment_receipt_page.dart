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
    return Scaffold(
      appBar: AppBar(title: const Text('支付成功')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 72),
          const SizedBox(height: 12),
          Text(
            '付款成功',
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
                  _ReceiptRow(label: '支付方式', value: receipt.method.label),
                  _ReceiptRow(label: '收款商户', value: receipt.merchantName),
                  _ReceiptRow(label: '商品', value: receipt.productSummary),
                  _ReceiptRow(label: '订单号', value: receipt.orderId),
                  _ReceiptRow(label: '交易号', value: receipt.transactionId),
                  _ReceiptRow(
                    label: '渠道参考号',
                    value: receipt.providerReference,
                  ),
                  _ReceiptRow(label: '支付时间', value: _formatTime(receipt.paidAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '请保留交易号以便查询。支付结果已通过服务端校验。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('完成并启动洗车'),
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
