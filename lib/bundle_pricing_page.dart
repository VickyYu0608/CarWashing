import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/l10n/localized_catalog.dart';
import 'package:car_washing_app/main.dart';
import 'package:car_washing_app/widgets/app_card.dart';
import 'package:car_washing_app/widgets/ui_motion.dart';
import 'package:flutter/material.dart';

/// Shared wash-credit bundle pricing editor (single / 10-pack / 20-pack).
class BundlePricingPage extends StatefulWidget {
  const BundlePricingPage({
    super.key,
    this.title,
    this.description,
    this.showStorePackageHint = false,
  });

  final String? title;
  final String? description;
  final bool showStorePackageHint;

  @override
  State<BundlePricingPage> createState() => _BundlePricingPageState();
}

class _BundlePricingPageState extends State<BundlePricingPage> {
  late List<Map<String, dynamic>> plans;
  bool loading = false;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    final cached = AppScope.of(context).bundlePlans;
    plans = cached.isNotEmpty
        ? List<Map<String, dynamic>>.from(cached)
        : List<Map<String, dynamic>>.from(AppStore.bundlePlanSpecs);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => refreshing = plans.isEmpty);
    final appStore = AppScope.of(context);
    try {
      final remote = await appStore.fetchBundlePlans(force: plans.isEmpty);
      if (!mounted) return;
      setState(() {
        plans = remote;
        refreshing = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        if (plans.isEmpty) {
          plans = List<Map<String, dynamic>>.from(AppStore.bundlePlanSpecs);
        }
        refreshing = false;
      });
    }
  }

  Future<void> _editPlan(Map<String, dynamic> plan) async {
    final s = context.s;
    final appStore = AppScope.of(context);
    final priceController = TextEditingController(
      text: (plan['price'] as num).toStringAsFixed(0),
    );
    final countController = TextEditingController(
      text: '${plan['wash_count']}',
    );
    final nameController = TextEditingController(
      text: s.catalog.bundlePlanName(
        plan['id'] as String,
        fallback: plan['name'] as String?,
      ),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogS = dialogContext.s;
        return AlertDialog(
          title: Text(dialogS.editBundlePlan),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogS.cancelBtn),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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
      final body = <String, dynamic>{
        'name': nameController.text.trim(),
        'wash_count': count,
        'price': price,
      };
      await appStore.updateBundlePlan(plan['id'] as String, body);
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
    final title = widget.title ?? s.platformPricing;
    final description = widget.description ?? s.platformPricingDesc;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          if (widget.showStorePackageHint) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.primarySurface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppIconBadge(
                      icon: Icons.storefront_outlined,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.storeWashPackagePricing,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.storeWashPackagePricingHint,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            s.washCreditBundlesSection,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            s.washCreditBundlesSectionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          if (refreshing && plans.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            for (var i = 0; i < plans.length; i++) ...[
              AppFadeSlideIn(
                delay: Duration(milliseconds: 50 * i),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => _editPlan(s.catalog.bundlePlans(plans)[i]),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primarySurface,
                          child: Text(
                            '${plans[i]['wash_count']}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.catalog.bundlePlans(plans)[i]['name'] as String? ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.catalog.bundlePlans(plans)[i]['description'] as String? ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              s.priceYuan(
                                (s.catalog.bundlePlans(plans)[i]['price'] as num)
                                    .toDouble(),
                              ),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.tapToEditPrice,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
