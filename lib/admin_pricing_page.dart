import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/l10n/localized_catalog.dart';
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
    final s = context.s;
    final priceController = TextEditingController(
      text: (plan['price'] as num).toStringAsFixed(0),
    );
    final countController = TextEditingController(
      text: '${plan['wash_count']}',
    );
    final nameController = TextEditingController(
      text: context.s.catalog.bundlePlanName(
        plan['id'] as String,
        fallback: plan['name'] as String?,
      ),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogS = context.s;
        return AlertDialog(
          title: Text(dialogS.editBundlePlan),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: dialogS.packageNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: dialogS.washCountLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: dialogS.priceYuanLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dialogS.cancelBtn),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(dialogS.saveBtn),
            ),
          ],
        );
      },
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
        throw StateError(s.priceFormatInvalid);
      }
      if (count == null || count <= 0) {
        throw StateError(s.countFormatInvalid);
      }
      await ApiClient.updateBundlePlan(plan['id'] as String, {
        'name': nameController.text.trim(),
        'wash_count': count,
        'price': price,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.bundlePricingUpdated)),
        );
      }
      await _load();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.saveFailedWithError(e))),
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
    final s = context.s;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.platformPricing,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            s.platformPricingDesc,
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
            for (final plan in s.catalog.bundlePlans(plans))
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
                      s.priceYuan((plan['price'] as num).toDouble()),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
