import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/bundle_purchase_page.dart';
import 'package:car_washing_app/main.dart';
import 'package:car_washing_app/customer_service_page.dart';
import 'package:car_washing_app/settings_page.dart';
import 'package:car_washing_app/share_referral.dart';
import 'package:car_washing_app/terms_page.dart';
import 'package:flutter/material.dart';

/// 用户个人中心
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final vehicles = appStore.vehiclesForUser(account.id);
        final addresses = appStore.addressesForUser(account.id);
        final orderCount = appStore.orders
                .where((order) => order.userAccountId == account.id)
                .length;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(account: account),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _OrderShortcutCard(
                    orderCount: orderCount,
                    onTap: () => switchUserShellTab(context, 2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AssetCard(
                          icon: Icons.directions_car_filled_outlined,
                          title: '我的车辆',
                          subtitle: vehicles.isEmpty
                              ? '添加车辆'
                              : '${vehicles.length} 辆',
                          onTap: () => _showVehicles(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AssetCard(
                          icon: Icons.location_on_outlined,
                          title: '常用地址',
                          subtitle: addresses.isEmpty
                              ? '添加地址'
                              : '${addresses.length} 个',
                          onTap: () => _showAddresses(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const AppIconBadge(
                        icon: Icons.confirmation_number_outlined,
                        size: 44,
                      ),
                      title: const Text('洗车次卡', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('剩余 ${account.prepaidWashCredits} 次 · 购买套餐'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BundlePurchasePage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const AppIconBadge(icon: Icons.stars_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '我的积分',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${account.freeWashCredits * 10}.00',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '免费洗车 ${account.freeWashCredits} 次',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (account.role == AccountRole.user) ...[
                    const SizedBox(height: 12),
                    ReferralProfileSection(
                      shareCode: account.shareCode,
                      freeWashCredits: account.freeWashCredits,
                      freeWashUsedCount: appStore.freeWashUsedCount(account.id),
                      referralSuccessCount: account.referredUserIds.length,
                      canShare: appStore.canShareReferral(account),
                      referredByName: account.referredByUserId == null
                          ? null
                          : appStore
                              .accountById(account.referredByUserId!)
                              .displayName,
                      referredUsers: [
                        for (final userId in account.referredUserIds)
                          appStore.accountById(userId).displayName,
                      ],
                      canRedeemCode: account.referredByUserId == null,
                      onRedeemCode: (code) async {
                        appStore.redeemReferralCode(code, forAccount: account);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _MenuSection(
                    items: [
                      _MenuItem(
                        icon: Icons.support_agent_outlined,
                        label: '联系客服',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerServicePage(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        label: '服务条款',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TermsPage(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        label: '个人设置',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: appStore.logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('退出登录'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVehicles(BuildContext context) {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    final vehicles = appStore.vehiclesForUser(account.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddItemSheet(
        title: '我的车辆',
        emptyText: '暂无车辆',
        items: [
          for (final vehicle in vehicles)
            ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: Text(vehicle.displayLabel),
            ),
        ],
        fields: const [
          _SheetField(key: 'model', label: '车型'),
          _SheetField(key: 'plate', label: '车牌号'),
          _SheetField(key: 'color', label: '颜色（选填）'),
        ],
        onSubmit: (values) {
          appStore.addVehicle(
            userAccountId: account.id,
            model: values['model'] ?? '',
            plate: values['plate'] ?? '',
            color: values['color'] ?? '',
          );
        },
      ),
    );
  }

  void _showAddresses(BuildContext context) {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    final addresses = appStore.addressesForUser(account.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddItemSheet(
        title: '常用地址',
        emptyText: '暂无地址',
        items: [
          for (final address in addresses)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(address.label),
              subtitle: Text(address.address),
            ),
        ],
        fields: const [
          _SheetField(key: 'label', label: '标签（如：家、公司）'),
          _SheetField(key: 'address', label: '详细地址'),
        ],
        onSubmit: (values) {
          appStore.addAddress(
            userAccountId: account.id,
            label: values['label'] ?? '',
            address: values['address'] ?? '',
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.account});

  final AppAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.22),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.phone,
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderShortcutCard extends StatelessWidget {
  const _OrderShortcutCard({
    required this.orderCount,
    required this.onTap,
  });

  final int orderCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const AppIconBadge(icon: Icons.receipt_long_outlined, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '全部订单',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '$orderCount 个订单',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconBadge(icon: icon, size: 40),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              leading: AppIconBadge(icon: items[i].icon, size: 40),
              title: Text(items[i].label),
              trailing: const Icon(Icons.chevron_right),
              onTap: items[i].onTap,
            ),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _SheetField {
  const _SheetField({required this.key, required this.label});

  final String key;
  final String label;
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final String emptyText;
  final List<Widget> items;
  final List<_SheetField> fields;
  final void Function(Map<String, String> values) onSubmit;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final controllers = <String, TextEditingController>{};
  String? error;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      controllers[field.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            Text(widget.emptyText)
          else
            ...widget.items,
          const SizedBox(height: 16),
          const Text('添加', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final field in widget.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: controllers[field.key],
                decoration: InputDecoration(labelText: field.label),
              ),
            ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final values = <String, String>{};
              for (final field in widget.fields) {
                values[field.key] = controllers[field.key]!.text.trim();
              }
              if (_hasEmptyRequired(values)) {
                setState(() => error = '请填写完整信息');
                return;
              }
              widget.onSubmit(values);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  bool _hasEmptyRequired(Map<String, String> values) {
    for (final field in widget.fields) {
      if (!field.label.contains('选填') && (values[field.key] ?? '').isEmpty) {
        return true;
      }
    }
    return false;
  }
}
