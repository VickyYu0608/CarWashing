import 'package:car_washing_app/l10n/app_locale.dart';
import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:car_washing_app/main.dart';
import 'package:car_washing_app/models/service_order.dart';

/// Resolves user-facing text for built-in catalog / demo content by stable ID.
/// Merchant- or user-created content falls back to the stored value.
class LocalizedCatalog {
  const LocalizedCatalog(this.locale);

  final AppLocale locale;

  factory LocalizedCatalog.from(AppStrings strings) =>
      LocalizedCatalog(strings.locale);

  String _from(
    Map<AppLocale, Map<String, String>> table,
    String id, {
    String? fallback,
  }) {
    return table[locale]?[id] ??
        table[AppLocale.en]?[id] ??
        fallback ??
        id;
  }

  // ── Bundle plans (platform wash credits) ─────────────────────────────────

  static const _bundleNames = {
    AppLocale.en: {
      'single': 'Single wash',
      'pack10': '10-wash package',
      'pack20': '20-wash package',
    },
    AppLocale.zhHans: {
      'single': '单次洗车',
      'pack10': '10次套餐',
      'pack20': '20次套餐',
    },
    AppLocale.zhHant: {
      'single': '單次洗車',
      'pack10': '10次套餐',
      'pack20': '20次套餐',
    },
  };

  static const _bundleDescs = {
    AppLocale.en: {
      'single': 'Buy and use instantly — flexible single wash',
    },
    AppLocale.zhHans: {
      'single': '即买即用，灵活单次',
    },
    AppLocale.zhHant: {
      'single': '即買即用，靈活單次',
    },
  };

  String bundlePlanName(String id, {String? fallback}) =>
      _from(_bundleNames, id, fallback: fallback);

  String bundlePlanDescription(
    String id, {
    required int washCount,
    required double price,
    String? fallback,
  }) {
    if (id == 'single') {
      return _from(_bundleDescs, id, fallback: fallback);
    }
    if (washCount > 1) {
      final avg = price / washCount;
      return switch (locale) {
        AppLocale.en => 'Average ¥${avg.toStringAsFixed(avg == avg.roundToDouble() ? 0 : 1)} per wash',
        AppLocale.zhHans =>
          '平均每单 ¥${avg.toStringAsFixed(avg == avg.roundToDouble() ? 0 : 1)}',
        AppLocale.zhHant =>
          '平均每單 ¥${avg.toStringAsFixed(avg == avg.roundToDouble() ? 0 : 1)}',
      };
    }
    return fallback ?? '';
  }

  List<Map<String, dynamic>> bundlePlans(List<Map<String, dynamic>> raw) {
    return [
      for (final plan in raw)
        {
          ...plan,
          'name': bundlePlanName(
            plan['id'] as String,
            fallback: plan['name'] as String?,
          ),
          'description': bundlePlanDescription(
            plan['id'] as String,
            washCount: plan['wash_count'] as int,
            price: (plan['price'] as num).toDouble(),
            fallback: plan['description'] as String?,
          ),
        },
    ];
  }

  // ── In-store wash packages ───────────────────────────────────────────────

  static const _packageNames = {
    AppLocale.en: {
      'quick': 'Quick rinse',
      'basic': 'Standard self-service',
      'premium': 'Premium wash',
    },
    AppLocale.zhHans: {
      'quick': '快速冲洗',
      'basic': '标准自助洗',
      'premium': '精洗套餐',
    },
    AppLocale.zhHant: {
      'quick': '快速沖洗',
      'basic': '標準自助洗',
      'premium': '精洗套餐',
    },
  };

  static const _packageDescs = {
    AppLocale.en: {
      'quick': 'Light dust — quick clean',
      'basic': 'Pressure wash, foam, and rinse',
      'premium': 'Foam, coating wax, and vacuum',
    },
    AppLocale.zhHans: {
      'quick': '适合轻度灰尘快速清洁',
      'basic': '高压水枪、泡沫、清水冲洗',
      'premium': '含泡沫、镀膜水蜡和吸尘',
    },
    AppLocale.zhHant: {
      'quick': '適合輕度灰塵快速清潔',
      'basic': '高壓水槍、泡沫、清水沖洗',
      'premium': '含泡沫、鍍膜水蠟和吸塵',
    },
  };

  String servicePackageName(String id, {String? fallback}) =>
      _from(_packageNames, id, fallback: fallback);

  String servicePackageDescription(String id, {String? fallback}) =>
      _from(_packageDescs, id, fallback: fallback);

  // ── Demo stores ────────────────────────────────────────────────────────

  static const _storeNames = {
    AppLocale.en: {
      'store-1': 'Blue Whale Self-Service · Central',
      'store-2': 'Jingchi Car Wash · Kwun Tong',
      'store-3': 'Station Manual Wash · Sha Tin',
    },
    AppLocale.zhHans: {
      'store-1': '蓝鲸自助洗车 中环店',
      'store-2': '净驰洗车 观塘店',
      'store-3': '驿站人工洗车 沙田店',
    },
    AppLocale.zhHant: {
      'store-1': '藍鯨自助洗車 中環店',
      'store-2': '淨馳洗車 觀塘店',
      'store-3': '驛站人工洗車 沙田店',
    },
  };

  static const _storeAddresses = {
    AppLocale.en: {
      'store-1': '88 Connaught Rd Central, Central, Hong Kong Island',
      'store-2': '21 Shing Yip St, Kwun Tong, Kowloon',
      'store-3': '3 Sha Tin Centre St, Sha Tin, New Territories',
    },
    AppLocale.zhHans: {
      'store-1': '香港港岛中西区干诺道中 88 号',
      'store-2': '香港九龙观塘区成业街 21 号',
      'store-3': '香港新界沙田区沙田正街 3 号',
    },
    AppLocale.zhHant: {
      'store-1': '香港港島中西區干諾道中 88 號',
      'store-2': '香港九龍觀塘區成業街 21 號',
      'store-3': '香港新界沙田區沙田正街 3 號',
    },
  };

  String storeName(String storeId, {required String fallback}) =>
      _from(_storeNames, storeId, fallback: fallback);

  String storeAddress(String storeId, {required String fallback}) =>
      _from(_storeAddresses, storeId, fallback: fallback);

  // ── Demo bays / devices ────────────────────────────────────────────────

  static const _bayNames = {
    AppLocale.en: {
      'D-1001': 'Self-service #1',
      'D-1002': 'Self-service #2',
      'D-1003': 'Self-service #3',
      'D-2001': 'Self-service Bay A',
      'D-2002': 'Self-service Bay B',
      'D-3001': 'Manual reception',
    },
    AppLocale.zhHans: {
      'D-1001': '自助1号',
      'D-1002': '自助2号',
      'D-1003': '自助3号',
      'D-2001': '自助A工位',
      'D-2002': '自助B工位',
      'D-3001': '人工接待位',
    },
    AppLocale.zhHant: {
      'D-1001': '自助1號',
      'D-1002': '自助2號',
      'D-1003': '自助3號',
      'D-2001': '自助A工位',
      'D-2002': '自助B工位',
      'D-3001': '人工接待位',
    },
  };

  String bayName(String deviceId, {required String fallback}) =>
      _from(_bayNames, deviceId, fallback: fallback);

  // ── Demo accounts ──────────────────────────────────────────────────────

  static const _accountNames = {
    AppLocale.en: {
      'user-demo': 'Demo user',
      'shop-demo': 'Blue Whale Ops',
      'admin-demo': 'Platform admin',
    },
    AppLocale.zhHans: {
      'user-demo': '演示用户',
      'shop-demo': '蓝鲸运营',
      'admin-demo': '平台管理员',
    },
    AppLocale.zhHant: {
      'user-demo': '演示用戶',
      'shop-demo': '藍鯨運營',
      'admin-demo': '平台管理員',
    },
  };

  String accountDisplayName(String accountId, {required String fallback}) =>
      _from(_accountNames, accountId, fallback: fallback);

  // ── Store tags ─────────────────────────────────────────────────────────

  static const _tags = {
    AppLocale.en: {
      '24小时': '24 hours',
      '自助': 'Self-service',
      '空闲多': 'Many idle bays',
      '人工精洗': 'Manual detail wash',
      '自助吸尘': 'Self vacuum',
      '人工洗车': 'Manual wash',
      '商场停车场': 'Mall parking',
      '新入驻': 'New',
      '新店铺': 'New store',
    },
    AppLocale.zhHans: {
      '24小时': '24小时',
      '自助': '自助',
      '空闲多': '空闲多',
      '人工精洗': '人工精洗',
      '自助吸尘': '自助吸尘',
      '人工洗车': '人工洗车',
      '商场停车场': '商场停车场',
      '新入驻': '新入驻',
      '新店铺': '新店铺',
    },
    AppLocale.zhHant: {
      '24小时': '24小時',
      '自助': '自助',
      '空闲多': '空閒多',
      '人工精洗': '人工精洗',
      '自助吸尘': '自助吸塵',
      '人工洗车': '人工洗車',
      '商场停车场': '商場停車場',
      '新入驻': '新入駐',
      '新店铺': '新店鋪',
    },
  };

  String storeTag(String tag) => _from(_tags, tag, fallback: tag);

  // ── Demo profile extras ────────────────────────────────────────────────

  String addressLabel(String label) => switch (label) {
        '家' => switch (locale) {
            AppLocale.en => 'Home',
            AppLocale.zhHans => '家',
            AppLocale.zhHant => '家',
          },
        _ => label,
      };

  String vehicleColor(String color) => switch (color) {
        '白色' => switch (locale) {
            AppLocale.en => 'White',
            AppLocale.zhHans => '白色',
            AppLocale.zhHant => '白色',
          },
        _ => color,
      };

  String vehicleModel(String vehicleId, {required String fallback}) {
    if (vehicleId == 'vehicle-1') {
      return switch (locale) {
        AppLocale.en => 'BMW i3',
        AppLocale.zhHans => '宝马 i3',
        AppLocale.zhHant => '寶馬 i3',
      };
    }
    return fallback;
  }

  String walletTransactionTitle(String id, {required String fallback}) {
    if (id == 'txn-1') {
      return switch (locale) {
        AppLocale.en => 'Standard self-service · 粤B·88888',
        AppLocale.zhHans => '标准自助洗 · 粤B·88888',
        AppLocale.zhHant => '標準自助洗 · 粵B·88888',
      };
    }
    return fallback;
  }
}

extension CatalogOnAppStrings on AppStrings {
  LocalizedCatalog get catalog => LocalizedCatalog(locale);
}

extension LocalizedBundlePlan on Map<String, dynamic> {
  String localizedName(AppStrings s) =>
      s.catalog.bundlePlanName(this['id'] as String, fallback: this['name'] as String?);

  String localizedDescription(AppStrings s) => s.catalog.bundlePlanDescription(
        this['id'] as String,
        washCount: this['wash_count'] as int,
        price: (this['price'] as num).toDouble(),
        fallback: this['description'] as String?,
      );
}

extension LocalizedServicePackage on ServicePackage {
  String localizedName([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.servicePackageName(id, fallback: name);
  }

  String localizedDescription([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.servicePackageDescription(id, fallback: description);
  }
}

extension LocalizedCarWashStore on CarWashStore {
  String localizedName([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.storeName(id, fallback: name);
  }

  String localizedAddress([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.storeAddress(id, fallback: address);
  }

  List<String> localizedTags([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return tags.map(s.catalog.storeTag).toList();
  }
}

extension LocalizedWashDevice on WashDevice {
  String localizedBayName([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.bayName(id, fallback: bayName);
  }
}

extension LocalizedAppAccount on AppAccount {
  String localizedDisplayName([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.accountDisplayName(id, fallback: displayName);
  }
}

extension LocalizedUserAddress on UserAddress {
  String localizedLabel([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.addressLabel(label);
  }
}

extension LocalizedUserVehicle on UserVehicle {
  String localizedColor([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.vehicleColor(color);
  }

  String localizedDisplayLabel([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    final modelName = s.catalog.vehicleModel(id, fallback: model);
    final colorText = color.isEmpty ? '' : localizedColor(s);
    return switch (s.locale) {
      AppLocale.en => colorText.isEmpty
          ? '$modelName · $plate'
          : '$modelName ($colorText) · $plate',
      _ => colorText.isEmpty
          ? '$modelName · $plate'
          : '$modelName（$colorText）· $plate',
    };
  }
}

extension LocalizedWalletTransaction on WalletTransaction {
  String localizedTitle([AppStrings? strings]) {
    final s = strings ?? AppStrings.current;
    return s.catalog.walletTransactionTitle(id, fallback: title);
  }
}
