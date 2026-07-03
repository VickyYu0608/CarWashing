import 'package:car_washing_app/app_theme.dart';
import 'package:flutter/material.dart';

enum PaymentMethod { wechat, alipay, simulate }

/// 统一支付收银台（模拟支付，预留真实通道）
class PaymentSheet {
  static Future<bool> show(
    BuildContext context, {
    required double amount,
    required String title,
    String subtitle = '',
  }) async {
    var method = PaymentMethod.simulate;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '确认支付',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '¥${amount.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MethodTile(
                    icon: Icons.chat_bubble_outline,
                    label: '微信支付',
                    selected: method == PaymentMethod.wechat,
                    onTap: () => setState(() => method = PaymentMethod.wechat),
                  ),
                  _MethodTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: '支付宝',
                    selected: method == PaymentMethod.alipay,
                    onTap: () => setState(() => method = PaymentMethod.alipay),
                  ),
                  _MethodTile(
                    icon: Icons.developer_mode_outlined,
                    label: '模拟支付（测试）',
                    selected: method == PaymentMethod.simulate,
                    onTap: () => setState(() => method = PaymentMethod.simulate),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确认支付'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return result == true;
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AppIconBadge(icon: icon, size: 40),
      title: Text(label),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
