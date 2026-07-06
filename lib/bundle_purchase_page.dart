import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/l10n/localized_catalog.dart';
import 'package:car_washing_app/main.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:car_washing_app/payment/payment_page.dart';
import 'package:flutter/material.dart';

/// 购买洗车次卡（单次 ¥50 / 10次 ¥450 / 20次 ¥850）
class BundlePurchasePage extends StatefulWidget {
  const BundlePurchasePage({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<BundlePurchasePage> createState() => _BundlePurchasePageState();
}

class _BundlePurchasePageState extends State<BundlePurchasePage> {
  List<Map<String, dynamic>> plans = List<Map<String, dynamic>>.from(
    AppStore.bundlePlanSpecs,
  );
  bool loading = false;
  String? error;
  String? purchasingPlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final appStore = AppScope.of(context);
    if (!appStore.shouldFetchBundlePlansFromBackend) {
      setState(() {
        plans = List<Map<String, dynamic>>.from(AppStore.bundlePlanSpecs);
        loading = false;
        error = null;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });
    try {
      final remotePlans = await appStore.fetchBundlePlans();
      if (!mounted) return;
      setState(() {
        plans = remotePlans;
        loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        plans = List<Map<String, dynamic>>.from(AppStore.bundlePlanSpecs);
        loading = false;
      });
    }
  }

  Future<void> _purchase(Map<String, dynamic> plan) async {
    final s = context.s;
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount;
    if (account == null) {
      return;
    }

    final planId = plan['id'] as String;
    final planName = plan.localizedName(s);
    final washCount = plan['wash_count'] as int;
    final amount = (plan['price'] as num).toDouble();

    setState(() => purchasingPlanId = planId);
    try {
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            checkout: PaymentCheckoutArgs(
              orderId:
                  'BUNDLE-$planId-${DateTime.now().millisecondsSinceEpoch}',
              storeName: s.appTitle,
              packageName: s.packageNameWithCount(planName, washCount),
              amount: amount,
              usedFreeWash: false,
              payerDisplayName: account.displayName,
              payerPhone: account.phone,
              onPaymentConfirmed: ({
                required transactionId,
                required method,
                providerReference,
              }) async {
                await appStore.purchaseBundle(
                  planId,
                  transactionId: transactionId,
                  paymentMethod: method.label,
                );
              },
            ),
          ),
        ),
      );

      if (paid != true || !mounted) {
        return;
      }

      final credits = appStore.currentAccount?.prepaidWashCredits ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.paymentSuccessMessage(washCount, credits)),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.purchaseFailedWithError(e))),
      );
    } finally {
      if (mounted) setState(() => purchasingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final localeController = LocaleScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([appStore, localeController]),
      builder: (context, _) {
        final account = appStore.currentAccount;
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildBody(context, appStore, account);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppStore appStore,
    AppAccount? account,
  ) {
    final s = context.s;
    final prepaidCredits = account?.prepaidWashCredits ?? 0;
    final freeCredits = account?.freeWashCredits ?? 0;
    final usageOrders = appStore.orders
        .where(
          (order) =>
              order.userAccountId == account?.id &&
              order.amount <= 0 &&
              !order.usedFreeWashCredit &&
              order.status != OrderStatus.created,
        )
        .take(5)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.embedded)
          SectionTitle(
            title: s.buyPackageLink,
            subtitle: s.buyPackagesSubtitle,
          ),
        if (widget.embedded) const SizedBox(height: 12),
        Card(
          color: AppColors.primarySurface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.myWashCredits,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        s.creditsSummary(prepaidCredits, freeCredits),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
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
        Text(
          s.selectPackage,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        for (final plan in context.s.catalog.bundlePlans(plans)) ...[
          _BundlePlanCard(
            plan: plan,
            purchasing: purchasingPlanId == plan['id'],
            onPurchase: () => _purchase(plan),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Text(
          s.recentUsage,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (usageOrders.isEmpty)
          EmptyState(
            icon: Icons.history,
            title: s.noUsageHistory,
            description: s.noUsageHistoryDesc,
          )
        else
          for (final order in usageOrders) ...[
            Card(
              child: ListTile(
                leading: const AppIconBadge(
                  icon: Icons.local_car_wash_outlined,
                  size: 40,
                ),
                title: Text(
                  _storeName(appStore, order.storeId),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${formatDateTime(order.createdAt)} · ${order.status.label}',
                ),
                trailing: Text(
                  s.creditsUsedOnce,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        Text(
          s.packagePaymentHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _storeName(AppStore appStore, String storeId) {
    final s = AppStrings.current;
    try {
      return appStore.storeById(storeId).localizedName(s);
    } on Object {
      return AppStrings.current.washStoreFallback;
    }
  }
}

class _BundlePlanCard extends StatelessWidget {
  const _BundlePlanCard({
    required this.plan,
    required this.purchasing,
    required this.onPurchase,
  });

  final Map<String, dynamic> plan;
  final bool purchasing;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'] as String? ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.washCountTimes(plan['wash_count'] as int)} · ${plan['description'] ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  s.priceYuan((plan['price'] as num).toDouble()),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: purchasing ? null : onPurchase,
                child: purchasing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.buyNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 独立打开时的带 AppBar 版本
class BundlePurchaseScaffold extends StatelessWidget {
  const BundlePurchaseScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.s.buyPackages)),
      body: const BundlePurchasePage(),
    );
  }
}
