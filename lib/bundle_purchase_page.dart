import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/main.dart';
import 'package:flutter/material.dart';

/// 购买洗车次卡（单次 ¥50 / 10次 ¥450 / 20次 ¥850）
class BundlePurchasePage extends StatefulWidget {
  const BundlePurchasePage({super.key});

  @override
  State<BundlePurchasePage> createState() => _BundlePurchasePageState();
}

class _BundlePurchasePageState extends State<BundlePurchasePage> {
  List<Map<String, dynamic>> plans = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      plans = await ApiClient.fetchBundles();
    } on Object catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _purchase(String planId) async {
    final appStore = AppScope.of(context);
    try {
      final result = await ApiClient.purchaseBundle(planId);
      final credits = result['prepaid_wash_credits'] as int? ?? 0;
      final account = appStore.currentAccount;
      if (account != null) {
        account.prepaidWashCredits = credits;
        appStore.notifyListeners();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '购买成功，已增加 ${result['wash_count_added']} 次洗车（剩余 $credits 次）',
          ),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('购买失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = AppScope.of(context).currentAccount;
    return Scaffold(
      appBar: AppBar(title: const Text('购买洗车次卡')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppColors.primarySurface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined,
                            color: AppColors.primary, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '我的洗车次卡',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '剩余 ${account?.prepaidWashCredits ?? 0} 次',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择套餐',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                for (final plan in plans) ...[
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        plan['name'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${plan['wash_count']} 次 · ${plan['description'] ?? ''}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '¥${(plan['price'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _purchase(plan['id'] as String),
                            child: const Text('立即购买'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '付款后次数自动到账，扫码洗车时可选择「使用次卡」免支付。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
