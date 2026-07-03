import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/main.dart';
import 'package:flutter/material.dart';

/// 商家钱包
class ShopWalletPage extends StatefulWidget {
  const ShopWalletPage({super.key});

  @override
  State<ShopWalletPage> createState() => _ShopWalletPageState();
}

class _ShopWalletPageState extends State<ShopWalletPage> {
  final amountController = TextEditingController();
  String? error;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final balance = appStore.shopWalletBalance(account.id);
        final transactions = appStore.walletTransactions;
        return Scaffold(
          appBar: AppBar(title: const Text('我的钱包')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: appGradientHeaderDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '可提现余额',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => _showWithdraw(context, balance),
                      child: const Text('提现'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '收入明细',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无交易记录')),
                )
              else
                for (final txn in transactions)
                  Card(
                    child: ListTile(
                      leading: AppIconBadge(
                        icon: txn.isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 40,
                      ),
                      title: Text(txn.title),
                      subtitle: Text(_formatTime(txn.createdAt)),
                      trailing: Text(
                        '${txn.isIncome ? '+' : ''}${txn.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: txn.isIncome ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  void _showWithdraw(BuildContext context, double balance) {
    amountController.text = balance.toStringAsFixed(2);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '提现到支付宝',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '提现金额',
                helperText: '可提现 ¥${balance.toStringAsFixed(2)}',
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null) {
                  setState(() => error = '请输入有效金额');
                  return;
                }
                try {
                  AppScope.of(context).withdrawShopWallet(amount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('提现申请已提交')),
                  );
                } on Object catch (exception) {
                  setState(() => error =
                      exception.toString().replaceFirst('Bad state: ', ''));
                }
              },
              child: const Text('确认提现'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
