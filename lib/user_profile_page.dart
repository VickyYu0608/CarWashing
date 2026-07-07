import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/bundle_purchase_page.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/l10n/localized_catalog.dart';
import 'package:car_washing_app/main.dart';
import 'package:car_washing_app/customer_service_page.dart';
import 'package:car_washing_app/settings_page.dart';
import 'package:car_washing_app/share_referral.dart';
import 'package:car_washing_app/terms_page.dart';
import 'package:car_washing_app/widgets/ui_motion.dart';
import 'package:flutter/material.dart';

/// 用户个人中心
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(account: account),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const AppIconBadge(
                        icon: Icons.confirmation_number_outlined,
                        size: 44,
                      ),
                      title: Text(
                        s.washCreditsCard,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        s.washCreditsRemainingSubtitle(
                          account.prepaidWashCredits,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BundlePurchaseScaffold(),
                        ),
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
                              .localizedDisplayName(),
                      referredUsers: [
                        for (final userId in account.referredUserIds)
                          appStore.accountById(userId).localizedDisplayName(),
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
                        label: s.contactCustomerService,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerServicePage(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        label: s.termsOfService,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TermsPage(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        label: s.personalSettingsPage,
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
                    label: Text(s.logout),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.account});

  final AppAccount account;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: Container(
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
        boxShadow: [
          BoxShadow(
            color: Color(0x331D6FE8),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.localizedDisplayName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
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
