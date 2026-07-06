import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/main.dart';
import 'package:flutter/material.dart';

enum _UserOrderTab { all, unpaid, inProgress, completed }

/// 用户自助洗车订单列表
class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final selfOrders = appStore.orders
            .where(
              (order) => order.userAccountId == appStore.currentAccount?.id,
            )
            .toList();
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrdersHeader(),
              Material(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: s.tabAll),
                    Tab(text: s.tabUnpaid),
                    Tab(text: s.tabInProgress),
                    Tab(text: s.tabCompleted),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(selfOrders, _UserOrderTab.all),
                    _buildList(selfOrders, _UserOrderTab.unpaid),
                    _buildList(selfOrders, _UserOrderTab.inProgress),
                    _buildList(selfOrders, _UserOrderTab.completed),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<WashOrder> selfOrders, _UserOrderTab tab) {
    final filtered = _filterSelf(selfOrders, tab);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _emptyTitle(context, tab),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _emptyHint(context, tab),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final order in filtered) ...[
          OrderCard(order: order),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<WashOrder> _filterSelf(List<WashOrder> orders, _UserOrderTab tab) {
    Iterable<WashOrder> result = orders;
    result = switch (tab) {
      _UserOrderTab.all => result,
      _UserOrderTab.unpaid =>
        result.where((o) => o.status == OrderStatus.created),
      _UserOrderTab.inProgress => result.where(
          (o) =>
              o.status == OrderStatus.running ||
              o.status == OrderStatus.starting ||
              o.status == OrderStatus.paid,
        ),
      _UserOrderTab.completed => result.where(
          (o) =>
              o.status == OrderStatus.completed ||
              o.status == OrderStatus.failed ||
              o.status == OrderStatus.refunded,
        ),
    };
    return result.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _emptyTitle(BuildContext context, _UserOrderTab tab) {
    final s = context.s;
    return switch (tab) {
      _UserOrderTab.all => s.noOrdersAll,
      _UserOrderTab.unpaid => s.noOrdersUnpaidTitle,
      _UserOrderTab.inProgress => s.noOrdersInProgressTitle,
      _UserOrderTab.completed => s.noOrdersCompletedTitle,
    };
  }

  String _emptyHint(BuildContext context, _UserOrderTab tab) {
    final s = context.s;
    return switch (tab) {
      _UserOrderTab.all => s.noOrdersAllHint,
      _UserOrderTab.unpaid => s.noOrdersUnpaidHint,
      _UserOrderTab.inProgress => s.noOrdersInProgressHint,
      _UserOrderTab.completed => s.noOrdersCompletedHint,
    };
  }
}

class _OrdersHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.myOrdersTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.selfServiceOrdersSubtitle,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
