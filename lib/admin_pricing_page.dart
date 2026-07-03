import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/app_theme.dart';
import 'package:flutter/material.dart';

/// Admin 平台次卡定价（单次 ¥50 / 10次 ¥450 / 20次 ¥850）
class AdminPricingPage extends StatefulWidget {
  const AdminPricingPage({super.key});

  @override
  State<AdminPricingPage> createState() => _AdminPricingPageState();
}

class _AdminPricingPageState extends State<AdminPricingPage> {
  List<Map<String, dynamic>> plans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      plans = await ApiClient.fetchBundles();
    } on Object {
      // keep previous
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _editPlan(Map<String, dynamic> plan) async {
    final priceController = TextEditingController(
      text: (plan['price'] as num).toStringAsFixed(0),
    );
    final countController = TextEditingController(
      text: '${plan['wash_count']}',
    );
    final nameController = TextEditingController(
      text: plan['name'] as String? ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑次卡套餐'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '套餐名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '洗车次数',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '售价（元）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true) {
      priceController.dispose();
      countController.dispose();
      nameController.dispose();
      return;
    }
    try {
      final price = double.tryParse(priceController.text.trim());
      final count = int.tryParse(countController.text.trim());
      if (price == null || price < 0) {
        throw StateError('价格格式不正确');
      }
      if (count == null || count <= 0) {
        throw StateError('次数格式不正确');
      }
      await ApiClient.updateBundlePlan(plan['id'] as String, {
        'name': nameController.text.trim(),
        'wash_count': count,
        'price': price,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('次卡定价已更新')),
        );
      }
      await _load();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      priceController.dispose();
      countController.dispose();
      nameController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '平台定价',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '管理用户洗车次卡套餐。门店单次洗车价格在商家端各店铺内修改。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            for (final plan in plans)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      '${plan['wash_count']}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    plan['name'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(plan['description'] as String? ?? ''),
                  trailing: FilledButton.tonal(
                    onPressed: () => _editPlan(plan),
                    child: Text(
                      '¥${(plan['price'] as num).toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
