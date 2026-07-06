import 'dart:async';

import 'package:car_washing_app/api_config.dart';
import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/geocoding_service.dart';
import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/license_file_viewer.dart';
import 'package:car_washing_app/license_materials_page.dart';
import 'package:car_washing_app/license_upload.dart';
import 'package:car_washing_app/main.dart';
import 'package:car_washing_app/customer_service_page.dart';
import 'package:car_washing_app/shop_reviews_page.dart';
import 'package:car_washing_app/shop_wallet_page.dart';
import 'package:flutter/material.dart';

/// 商家端「我的」— 个人中心主页（展示 + 入口，非注册表单）
class ShopProfilePage extends StatelessWidget {
  const ShopProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final s = context.s;
        final account = appStore.currentAccount!;
        final storeCount = appStore.storesForCurrentShop().length;
        final balance = appStore.shopWalletBalance(account.id);
        final imageFiles =
            account.licenseFiles.where(isLicenseImageFile).toList();

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _ShopProfileHeader(account: account),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardStatCard(
                          label: s.todayCompleted,
                          value: s.todayCompletedValue(
                            appStore.todayCompletedOrderCount,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardStatCard(
                          label: s.todayRevenue,
                          value: '¥${appStore.todayRevenue.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const AppIconBadge(icon: Icons.account_balance_wallet_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.walletBalance,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '¥${balance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ShopWalletPage(),
                              ),
                            ),
                            child: Text(s.viewBtn),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.commonTools,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _ToolItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: s.walletShort,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ShopWalletPage(),
                              ),
                            ),
                          ),
                          _ToolItem(
                            icon: Icons.reviews_outlined,
                            label: s.reviewsShort,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ShopReviewsPage(),
                              ),
                            ),
                          ),
                          _ToolItem(
                            icon: Icons.support_agent_outlined,
                            label: s.customerServiceShort,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CustomerServicePage(),
                              ),
                            ),
                          ),
                          _ToolItem(
                            icon: Icons.settings_outlined,
                            label: s.settingsShort,
                            onTap: () => _openEdit(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (account.adminReply.isNotEmpty) ...[
                    _NoticeBanner(text: account.adminReply),
                    const SizedBox(height: 12),
                  ],
                  _ProfileSection(
                    title: s.accountInfo,
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.badge_outlined,
                        label: s.loginAccount,
                        value: account.username,
                        onTap: () => _openEdit(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileInfoTile(
                        icon: Icons.phone_iphone_outlined,
                        label: s.phone,
                        value: account.phone,
                        onTap: () => _openEdit(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileInfoTile(
                        icon: Icons.storefront_outlined,
                        label: s.merchantName,
                        value: account.displayName,
                        onTap: () => _openEdit(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileSection(
                    title: s.shopInfoSection,
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.location_on_outlined,
                        label: s.shopAddressLabel,
                        value: account.shopAddress.isEmpty
                            ? s.notFilled
                            : account.shopAddress,
                        onTap: () => _openEdit(context),
                      ),
                      if (account.shopLatitude != null &&
                          account.shopLongitude != null) ...[
                        const Divider(height: 1, indent: 56),
                        _ProfileInfoTile(
                          icon: Icons.map_outlined,
                          label: s.mapCoordinates,
                          value:
                              '${account.shopLatitude!.toStringAsFixed(4)}, ${account.shopLongitude!.toStringAsFixed(4)}',
                          onTap: () => _openEdit(context),
                        ),
                      ],
                      const Divider(height: 1, indent: 56),
                      _ProfileInfoTile(
                        icon: Icons.store_mall_directory_outlined,
                        label: s.manageStores,
                        value: s.storeCountBadge(storeCount),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ShopStoresPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileSection(
                    title: s.operatingLicense,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            const AppIconBadge(
                              icon: Icons.folder_open_outlined,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.fileCountBadge(account.licenseFiles.length),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    account.licenseFiles.isEmpty
                                        ? s.uploadBusinessLicense
                                        : account.licenseFiles.join('、'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: account.licenseFiles.isEmpty
                                  ? () => _openEdit(context)
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LicenseMaterialsPage(
                                            title: s.licenseTitleSuffix(
                                              account.displayName,
                                            ),
                                            files: account.licenseFiles,
                                          ),
                                        ),
                                      ),
                              child: Text(
                                account.licenseFiles.isEmpty
                                    ? s.goUpload
                                    : s.viewBtn,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (imageFiles.isNotEmpty)
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            itemCount: imageFiles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final file = imageFiles[index];
                              return GestureDetector(
                                onTap: () => LicenseImageFullScreenPage.open(
                                  context,
                                  file,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    licenseFileUrl(file),
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 88,
                                      color: AppColors.primarySurface,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openEdit(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(s.editProfile),
                  ),
                  const SizedBox(height: 10),
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

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopProfileEditPage()),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconBadge(icon: icon, size: 40),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ShopProfileHeader extends StatelessWidget {
  const _ShopProfileHeader({required this.account});

  final AppAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            account.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            account.phone,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              account.approvalStatus.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  }) : showChevron = true;

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AppIconBadge(icon: icon, size: 40),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 商家资料编辑页（从个人中心进入，类似「编辑资料」子页面）
class ShopProfileEditPage extends StatefulWidget {
  const ShopProfileEditPage({super.key});

  @override
  State<ShopProfileEditPage> createState() => _ShopProfileEditPageState();
}

class _ShopProfileEditPageState extends State<ShopProfileEditPage> {
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final displayNameController = TextEditingController();
  final addressController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final licenseFiles = <String>[];
  bool initialized = false;
  bool saving = false;
  bool geocoding = false;
  String? error;
  String? geocodingMessage;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    addressController.addListener(_scheduleGeocode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) {
      return;
    }
    final account = AppScope.of(context).currentAccount!;
    usernameController.text = account.username;
    phoneController.text = account.phone;
    displayNameController.text = account.displayName;
    addressController.text = account.shopAddress;
    latController.text = account.shopLatitude?.toStringAsFixed(6) ?? '';
    lngController.text = account.shopLongitude?.toStringAsFixed(6) ?? '';
    licenseFiles
      ..clear()
      ..addAll(account.licenseFiles);
    initialized = true;
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    addressController.removeListener(_scheduleGeocode);
    usernameController.dispose();
    phoneController.dispose();
    displayNameController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  void _scheduleGeocode() {
    if (!initialized) {
      return;
    }
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_geocodeAddress());
    });
  }

  Future<void> _geocodeAddress() async {
    final address = addressController.text.trim();
    if (address.isEmpty) {
      return;
    }
    setState(() {
      geocoding = true;
      geocodingMessage = null;
    });
    try {
      final result = await GeocodingService.geocode(address);
      if (!mounted) {
        return;
      }
      setState(() {
        latController.text = result.position.latitude.toStringAsFixed(6);
        lngController.text = result.position.longitude.toStringAsFixed(6);
        final s = context.s;
        geocodingMessage = result.formattedAddress == null
            ? s.geocodeCoordsUpdated
            : s.geocodeLocated(result.formattedAddress!);
      });
    } on GeocodingException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => geocodingMessage = exception.message);
    } on Object catch (geocodeError) {
      if (!mounted) {
        return;
      }
      setState(() => geocodingMessage = context.s.geocodeFailedMsg(geocodeError));
    } finally {
      if (mounted) {
        setState(() => geocoding = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    try {
      _validateShopProfile([
        usernameController.text,
        phoneController.text,
        displayNameController.text,
        addressController.text,
        latController.text,
        lngController.text,
      ]);
      if (licenseFiles.isEmpty) {
        throw StateError(AppStrings.current.uploadAtLeastOneLicense);
      }
      final latitude = double.tryParse(latController.text.trim());
      final longitude = double.tryParse(lngController.text.trim());
      if (latitude == null || longitude == null) {
        throw StateError(AppStrings.current.latLngFormatInvalid);
      }
      setState(() {
        saving = true;
        error = null;
      });
      appStore.updateShopProfile(
        account: account,
        username: usernameController.text,
        phone: phoneController.text,
        displayName: displayNameController.text,
        address: addressController.text,
        latitude: latitude,
        longitude: longitude,
        licenseFiles: licenseFiles,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.profileSaved)),
      );
      Navigator.of(context).pop();
    } on Object catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error =
          exception.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.editProfile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.profileSyncHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _EditSection(
            title: s.accountSection,
            children: [
              AppTextField(controller: usernameController, label: s.loginAccount),
              AppTextField(controller: phoneController, label: s.phone),
              AppTextField(controller: displayNameController, label: s.merchantName),
            ],
          ),
          const SizedBox(height: 16),
          _EditSection(
            title: s.addressAndCoordinates,
            children: [
              AppTextField(controller: addressController, label: s.shopAddressLabel),
              if (geocoding) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (geocodingMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  geocodingMessage!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: AppTextField(controller: latController, label: s.latitude),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(controller: lngController, label: s.longitude),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _EditSection(
            title: s.operatingLicense,
            children: [
              LicenseUploadSection(
                files: licenseFiles,
                onChanged: (files) => setState(() {
                  licenseFiles
                    ..clear()
                    ..addAll(files);
                  error = null;
                }),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : _saveProfile,
            child: Text(saving ? s.saving : s.save),
          ),
        ],
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

void _validateShopProfile(List<String> values) {
  if (values.any((value) => value.trim().isEmpty)) {
    throw StateError(AppStrings.current.fillAllRequired);
  }
}
