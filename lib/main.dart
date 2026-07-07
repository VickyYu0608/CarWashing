import 'dart:async';
import 'dart:math';

import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/api_config.dart';
import 'package:car_washing_app/app_sync.dart';
import 'package:car_washing_app/car_wash_map.dart';
import 'package:car_washing_app/country_codes.dart';
import 'package:car_washing_app/hk_district_picker.dart';
import 'package:car_washing_app/hk_districts.dart';
import 'package:car_washing_app/hk_sub_areas.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:car_washing_app/payment/payment_page.dart';
import 'package:car_washing_app/geocoding_service.dart';
import 'package:car_washing_app/license_materials_page.dart';
import 'package:car_washing_app/license_upload.dart';
import 'package:car_washing_app/models/service_order.dart';
import 'package:car_washing_app/share_referral.dart';
import 'package:car_washing_app/shop_profile_page.dart';
import 'package:car_washing_app/user_orders_page.dart';
import 'package:car_washing_app/user_profile_page.dart';
import 'package:car_washing_app/qr_scan_page.dart';
import 'package:car_washing_app/admin_approval_page.dart';
import 'package:car_washing_app/admin_pricing_page.dart';
import 'package:car_washing_app/shop_pricing_page.dart';
import 'package:car_washing_app/bundle_purchase_page.dart';
import 'package:car_washing_app/l10n/app_locale.dart';
import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/l10n/localized_catalog.dart';
import 'package:car_washing_app/widgets/app_performance.dart';
import 'package:car_washing_app/widgets/language_switcher.dart';
import 'package:car_washing_app/widgets/ui_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CarWashingApp());
}

const LatLng fallbackUserLocation = LatLng(22.2819, 114.1589);

class CarWashingApp extends StatefulWidget {
  const CarWashingApp({super.key});

  @override
  State<CarWashingApp> createState() => _CarWashingAppState();
}

class _CarWashingAppState extends State<CarWashingApp> {
  final AppStore store = AppStore.seeded();
  final LocaleController localeController = LocaleController();

  @override
  void dispose() {
    store.dispose();
    localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: localeController,
      child: AppScope(
        store: store,
        child: ListenableBuilder(
          listenable: localeController,
          builder: (context, _) {
            final s = localeController.strings;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: s.appTitle,
              theme: buildAppTheme(),
              locale: localeController.flutterLocale,
              supportedLocales: const [
                Locale('en'),
                Locale('zh', 'CN'),
                Locale('zh', 'TW'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({required AppStore store, required super.child, super.key})
      : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}

enum AccountRole { user, shop, admin }

enum ApprovalStatus { pending, approved, rejected }

enum WashServiceType { selfService, manual }

enum DeviceStatus { idle, busy, offline, faulted }

enum OrderStatus {
  created,
  paid,
  starting,
  running,
  completed,
  failed,
  refunded,
}

enum ReservationStatus { pending, arrived, completed, cancelled }

class AppAccount {
  AppAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
    required this.phone,
    this.approvalStatus = ApprovalStatus.pending,
    this.shopAddress = '',
    this.shopLatitude,
    this.shopLongitude,
    List<String>? licenseFiles,
    this.adminReply = '',
    this.shareCode = '',
    this.freeWashCredits = 0,
    this.prepaidWashCredits = 0,
    this.referredByUserId,
    List<String>? referredUserIds,
    this.autoUseFreeWash = true,
  })  : licenseFiles = licenseFiles ?? [],
        referredUserIds = referredUserIds ?? [];

  final String id;
  String username;
  String password;
  final AccountRole role;
  String displayName;
  String phone;
  ApprovalStatus approvalStatus;
  String shopAddress;
  double? shopLatitude;
  double? shopLongitude;
  List<String> licenseFiles;
  String adminReply;
  String shareCode;
  int freeWashCredits;
  int prepaidWashCredits;
  String? referredByUserId;
  List<String> referredUserIds;
  bool autoUseFreeWash;
}

class ServicePackage {
  const ServicePackage({
    required this.id,
    required this.name,
    required this.minutes,
    required this.price,
    required this.description,
  });

  final String id;
  final String name;
  final int minutes;
  final double price;
  final String description;
}

class WashDevice {
  WashDevice({
    required this.id,
    required this.qrCode,
    required this.bayName,
    required this.status,
    required this.lastHeartbeat,
    this.totalUseSeconds = 0,
    this.useCount = 0,
    this.faultCount = 0,
  });

  final String id;
  final String qrCode;
  final String bayName;
  DeviceStatus status;
  DateTime lastHeartbeat;
  int totalUseSeconds;
  int useCount;
  int faultCount;
}

class CarWashStore {
  CarWashStore({
    required this.id,
    required this.ownerAccountId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.tags,
    required this.serviceTypes,
    required this.devices,
    required this.packages,
    this.approvalStatus = ApprovalStatus.approved,
    this.adminReply = '',
  });

  final String id;
  final String ownerAccountId;
  String name;
  String address;
  double latitude;
  double longitude;
  final double rating;
  final List<String> tags;
  Set<WashServiceType> serviceTypes;
  final List<WashDevice> devices;
  final List<ServicePackage> packages;
  ApprovalStatus approvalStatus;
  String adminReply;

  LatLng get position => LatLng(latitude, longitude);
}

class WashOrder {
  WashOrder({
    required this.id,
    required this.userAccountId,
    required this.storeId,
    required this.deviceId,
    required this.packageId,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.remainingSeconds = 0,
    this.failureReason,
    this.usedFreeWashCredit = false,
    this.paymentTransactionId,
    this.paymentMethod,
    this.providerReference,
    this.paidAt,
  });

  final String id;
  final String userAccountId;
  final String storeId;
  final String deviceId;
  final String packageId;
  OrderStatus status;
  final double amount;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? finishedAt;
  int remainingSeconds;
  String? failureReason;
  final bool usedFreeWashCredit;
  String? paymentTransactionId;
  String? paymentMethod;
  String? providerReference;
  DateTime? paidAt;
}

class Reservation {
  Reservation({
    required this.id,
    required this.userAccountId,
    required this.storeId,
    required this.serviceType,
    required this.userLocation,
    required this.distanceKm,
    required this.etaMinutes,
    required this.arrivalTime,
    required this.contactPhone,
    required this.note,
    required this.createdAt,
    this.status = ReservationStatus.pending,
  });

  final String id;
  final String userAccountId;
  final String storeId;
  final WashServiceType serviceType;
  final LatLng userLocation;
  final double distanceKm;
  final int etaMinutes;
  final DateTime arrivalTime;
  final String contactPhone;
  final String note;
  final DateTime createdAt;
  ReservationStatus status;
}

class AppStore extends ChangeNotifier {
  AppStore.seeded()
      : accounts = _seedAccounts(),
        stores = _seedStores(),
        orders = _seedOrders(),
        reservations = [],
        userVehicles = _seedUserVehicles(),
        userAddresses = _seedUserAddresses(),
        shopWalletBalances = {'shop-demo': 1286.5},
        walletTransactions = _seedWalletTransactions();

  final List<AppAccount> accounts;
  final List<CarWashStore> stores;
  final List<WashOrder> orders;
  final List<Reservation> reservations;
  final Map<String, List<UserVehicle>> userVehicles;
  final Map<String, List<UserAddress>> userAddresses;
  final Map<String, double> shopWalletBalances;
  final List<WalletTransaction> walletTransactions;
  List<Map<String, dynamic>> bundlePlans =
      List<Map<String, dynamic>>.from(bundlePlanSpecs);
  AppAccount? currentAccount;
  String? lastReservationPhone;
  String? lastAuthMessage;
  bool isSyncing = false;
  String? lastSyncError;
  final ValueNotifier<int> orderTick = ValueNotifier(0);
  final ValueNotifier<int> catalogTick = ValueNotifier(0);
  final ValueNotifier<AppSyncUiState> syncUi =
      ValueNotifier(const AppSyncUiState());
  List<CarWashStore>? _approvedStoresCache;
  Timer? _washTimer;

  void _publishSyncUi({bool clearError = false}) {
    syncUi.value = AppSyncUiState(
      isSyncing: isSyncing,
      lastSyncError: clearError ? null : lastSyncError,
    );
  }

  void _touchCatalog() {
    _approvedStoresCache = null;
    catalogTick.value++;
  }

  Future<bool> login(String username, String password) async {
    lastAuthMessage = null;
    final trimmed = username.trim();
    if (!_shouldUseBackendApi()) {
      return _loginLocal(trimmed, password);
    }
    try {
      await ApiClient.login(trimmed, password);
      final me = await ApiClient.getMe();
      final account = _upsertAccountFromApi(me, password: password);
      if (account.approvalStatus != ApprovalStatus.approved) {
        if (account.role == AccountRole.shop) {
          currentAccount = account;
          notifyListeners();
          return true;
        }
        lastAuthMessage = account.approvalStatus == ApprovalStatus.pending
            ? AppStrings.current.accountPending
            : AppStrings.current.accountRejected;
        notifyListeners();
        return false;
      }
      currentAccount = account;
      lastReservationPhone ??= account.phone;
      if (account.role == AccountRole.admin) {
        unawaited(syncAccountsFromBackend());
      } else {
        unawaited(syncFromBackend());
      }
      notifyListeners();
      return true;
    } on ApiConnectionException {
      if (trimmed == 'user' || trimmed == 'shop' || trimmed == 'admin') {
        return _loginLocal(trimmed, password);
      }
      lastAuthMessage = AppStrings.current.backendUnreachable;
      notifyListeners();
      return false;
    } on ApiException catch (exception) {
      lastAuthMessage = exception.message;
      notifyListeners();
      return false;
    }
  }

  bool _loginLocal(String username, String password) {
    lastAuthMessage = null;
    for (final account in accounts) {
      if (account.username == username.trim() && account.password == password) {
        if (account.approvalStatus != ApprovalStatus.approved) {
          if (account.role == AccountRole.shop) {
            currentAccount = account;
            notifyListeners();
            return true;
          } else {
            lastAuthMessage = account.approvalStatus == ApprovalStatus.pending
                ? AppStrings.current.accountPending
                : AppStrings.current.accountRejected;
            notifyListeners();
            return false;
          }
        }
        currentAccount = account;
        lastReservationPhone ??= account.phone;
        notifyListeners();
        return true;
      }
    }
    lastAuthMessage = AppStrings.current.accountMismatch;
    return false;
  }

  Future<void> syncFromBackend() async {
    if (ApiClient.accessToken == null || currentAccount == null || isSyncing) {
      return;
    }
    isSyncing = true;
    lastSyncError = null;
    _publishSyncUi(clearError: true);
    notifyListeners();
    try {
      final account = currentAccount!;
      final storeFuture = account.role == AccountRole.shop
          ? ApiClient.fetchMyStores()
          : ApiClient.fetchStores();
      final results = await Future.wait([
        storeFuture,
        ApiClient.fetchOrders(),
        ApiClient.fetchReservations(),
        ApiClient.fetchBundles(),
      ]);
      final storeJson = results[0];
      final orderJson = results[1];
      final resJson = results[2];
      final bundleJson = results[3];

      stores
        ..clear()
        ..addAll(AppSync.parseStores(storeJson));
      orders
        ..clear()
        ..addAll(AppSync.parseOrders(orderJson));
      reservations
        ..clear()
        ..addAll(AppSync.parseReservations(resJson));
      bundlePlans = bundleJson;
      _touchCatalog();
      lastSyncError = null;
      _publishSyncUi(clearError: true);
      notifyListeners();

      unawaited(_syncSecondaryProfileData(account));
    } on ApiException catch (exception) {
      lastSyncError = exception.message;
      _publishSyncUi();
    } on ApiConnectionException catch (exception) {
      lastSyncError = exception.message;
      _publishSyncUi();
    } on Object catch (error) {
      lastSyncError = error.toString();
      _publishSyncUi();
    } finally {
      isSyncing = false;
      _publishSyncUi();
      notifyListeners();
    }
  }

  Future<void> _syncSecondaryProfileData(AppAccount account) async {
    try {
      if (account.role == AccountRole.user) {
        final profileResults = await Future.wait([
          ApiClient.fetchVehicles(),
          ApiClient.fetchAddresses(),
        ]);
        userVehicles[account.id] =
            AppSync.parseVehicles(profileResults[0]);
        userAddresses[account.id] =
            AppSync.parseAddresses(profileResults[1]);
      }

      if (account.role == AccountRole.shop) {
        final wallet = await ApiClient.fetchWallet();
        shopWalletBalances[account.id] =
            (wallet['balance'] as num?)?.toDouble() ?? 0;
        walletTransactions
          ..clear()
          ..addAll(
            AppSync.parseWalletTransactions(
              (wallet['transactions'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>(),
            ),
          );
      }
      notifyListeners();
    } on Object {
      // Profile/wallet data is non-blocking for the main UI.
    }
  }

  Future<void> syncAccountsFromBackend() async {
    if (ApiClient.accessToken == null) {
      return;
    }
    try {
      final remoteAccounts = await ApiClient.fetchAccounts();
      for (final json in remoteAccounts) {
        _upsertAccountFromApi(json);
      }
      notifyListeners();
    } on Object {
      // Keep local data if sync fails.
    }
  }

  AppAccount _upsertAccountFromApi(
    Map<String, dynamic> json, {
    String? password,
  }) {
    final id = json['id'] as String;
    final username = json['username'] as String;
    final existingIndex = accounts.indexWhere(
      (account) => account.id == id || account.username == username,
    );
    if (existingIndex >= 0) {
      final existing = accounts[existingIndex];
      _applyApiAccount(existing, json);
      if (password != null && password.isNotEmpty) {
        existing.password = password;
      }
      return existing;
    }
    final account = _accountFromApiJson(json, password: password ?? '');
    accounts.add(account);
    return account;
  }

  AppAccount _accountFromApiJson(
    Map<String, dynamic> json, {
    required String password,
  }) {
    final licenseFiles = (json['license_files'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final referredUserIds = (json['referred_user_ids'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    return AppAccount(
      id: json['id'] as String,
      username: json['username'] as String,
      password: password,
      role: _accountRoleFromApi(json['role'] as String),
      displayName: json['display_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      approvalStatus: _approvalStatusFromApi(
        json['approval_status'] as String? ?? 'pending',
      ),
      shopAddress: json['shop_address'] as String? ?? '',
      shopLatitude: (json['shop_latitude'] as num?)?.toDouble(),
      shopLongitude: (json['shop_longitude'] as num?)?.toDouble(),
      licenseFiles: licenseFiles,
      adminReply: json['admin_reply'] as String? ?? '',
      shareCode: json['share_code'] as String? ?? '',
      freeWashCredits: json['free_wash_credits'] as int? ?? 0,
      prepaidWashCredits: json['prepaid_wash_credits'] as int? ?? 0,
      referredByUserId: json['referred_by_user_id'] as String?,
      referredUserIds: referredUserIds,
      autoUseFreeWash: json['auto_use_free_wash'] as bool? ?? true,
    );
  }

  void _applyApiAccount(AppAccount target, Map<String, dynamic> json) {
    target.displayName =
        json['display_name'] as String? ?? target.displayName;
    target.phone = json['phone'] as String? ?? target.phone;
    target.approvalStatus = _approvalStatusFromApi(
      json['approval_status'] as String? ?? target.approvalStatus.name,
    );
    target.shopAddress = json['shop_address'] as String? ?? target.shopAddress;
    target.shopLatitude =
        (json['shop_latitude'] as num?)?.toDouble() ?? target.shopLatitude;
    target.shopLongitude =
        (json['shop_longitude'] as num?)?.toDouble() ?? target.shopLongitude;
    target.licenseFiles = (json['license_files'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    target.adminReply = json['admin_reply'] as String? ?? target.adminReply;
    target.shareCode = json['share_code'] as String? ?? target.shareCode;
    target.freeWashCredits =
        json['free_wash_credits'] as int? ?? target.freeWashCredits;
    target.prepaidWashCredits =
        json['prepaid_wash_credits'] as int? ?? target.prepaidWashCredits;
    target.referredByUserId =
        json['referred_by_user_id'] as String? ?? target.referredByUserId;
    target.referredUserIds =
        (json['referred_user_ids'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList();
    target.autoUseFreeWash =
        json['auto_use_free_wash'] as bool? ?? target.autoUseFreeWash;
  }

  AccountRole _accountRoleFromApi(String value) {
    switch (value) {
      case 'shop':
        return AccountRole.shop;
      case 'admin':
        return AccountRole.admin;
      default:
        return AccountRole.user;
    }
  }

  ApprovalStatus _approvalStatusFromApi(String value) {
    switch (value) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }

  String _approvalStatusToApi(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
      case ApprovalStatus.pending:
        return 'pending';
    }
  }

  String _washServiceTypeToApi(WashServiceType type) {
    switch (type) {
      case WashServiceType.selfService:
        return 'selfService';
      case WashServiceType.manual:
        return 'manual';
    }
  }

  bool _shouldUseBackendApi() {
    return ApiClient.useBackend;
  }

  static const List<Map<String, dynamic>> bundlePlanSpecs = [
    {
      'id': 'single',
      'wash_count': 1,
      'price': 50,
    },
    {
      'id': 'pack10',
      'wash_count': 10,
      'price': 450,
    },
    {
      'id': 'pack20',
      'wash_count': 20,
      'price': 850,
    },
  ];

  /// Locale-neutral bundle specs; use [LocalizedCatalog] for display text.
  static List<Map<String, dynamic>> get defaultBundlePlans => bundlePlanSpecs;

  Future<Map<String, dynamic>> purchaseBundle(
    String planId, {
    String? transactionId,
    String? paymentMethod,
  }) async {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.user) {
      throw StateError(AppStrings.current.errLoginAsUser);
    }
    final plan = bundlePlans.cast<Map<String, dynamic>>().firstWhere(
          (candidate) => candidate['id'] == planId,
          orElse: () => throw StateError(AppStrings.current.errPackageNotFound),
        );
    final washCount = plan['wash_count'] as int;

    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      try {
        final result = await ApiClient.purchaseBundle(planId);
        account.prepaidWashCredits =
            result['prepaid_wash_credits'] as int? ?? account.prepaidWashCredits;
        notifyListeners();
        return {
          ...result,
          if (transactionId != null) 'transaction_id': transactionId,
          if (paymentMethod != null) 'payment_method': paymentMethod,
        };
      } on ApiConnectionException {
        // Fall back to local purchase when backend is unavailable.
      }
    }

    account.prepaidWashCredits += washCount;
    notifyListeners();
    return {
      'prepaid_wash_credits': account.prepaidWashCredits,
      'wash_count_added': washCount,
      if (transactionId != null) 'transaction_id': transactionId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
    };
  }

  Future<List<Map<String, dynamic>>> fetchBundlePlans() async {
    if (!shouldFetchBundlePlansFromBackend) {
      return List<Map<String, dynamic>>.from(bundlePlans);
    }
    final remote = await ApiClient.fetchBundles();
    bundlePlans = remote;
    notifyListeners();
    return remote;
  }

  /// Always refetches bundle pricing from the API (e.g. after shop edits prices).
  Future<void> refreshBundlePlans() => fetchBundlePlans();

  Future<void> updateBundlePlan(
    String planId,
    Map<String, dynamic> body,
  ) async {
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final updated = await ApiClient.updateBundlePlan(planId, body);
      final idx = bundlePlans.indexWhere((plan) => plan['id'] == planId);
      if (idx >= 0) {
        bundlePlans[idx] = {...bundlePlans[idx], ...updated};
      } else {
        bundlePlans.add(updated);
      }
      notifyListeners();
      return;
    }
    final idx = bundlePlans.indexWhere((plan) => plan['id'] == planId);
    if (idx < 0) {
      throw StateError(AppStrings.current.errPackageNotFound);
    }
    final current = Map<String, dynamic>.from(bundlePlans[idx]);
    if (body['price'] != null) current['price'] = body['price'];
    if (body['wash_count'] != null) {
      current['wash_count'] = body['wash_count'];
    }
    if (body['name'] != null) current['name'] = body['name'];
    bundlePlans[idx] = current;
    notifyListeners();
  }

  bool get shouldFetchBundlePlansFromBackend => _shouldUseBackendApi();

  void logout() {
    currentAccount = null;
    ApiClient.accessToken = null;
    notifyListeners();
  }

  Future<AppAccount> registerUser({
    required String countryCode,
    required String phone,
    required String email,
    required String verificationCode,
    required String password,
    required String displayName,
    String referralCode = '',
  }) async {
    if (!_shouldUseBackendApi()) {
      return _registerUserLocal(
        countryCode: countryCode,
        phone: phone,
        email: email,
        verificationCode: verificationCode,
        password: password,
        displayName: displayName,
        referralCode: referralCode,
      );
    }
    try {
      final data = await ApiClient.registerUser(
        countryCode: countryCode,
        phone: phone,
        email: email,
        verificationCode: verificationCode,
        password: password,
        displayName: displayName,
        referralCode: referralCode,
      );
      final account = _upsertAccountFromApi(data, password: password);
      notifyListeners();
      return account;
    } on ApiException {
      rethrow;
    } on ApiConnectionException {
      return _registerUserLocal(
        countryCode: countryCode,
        phone: phone,
        email: email,
        verificationCode: verificationCode,
        password: password,
        displayName: displayName,
        referralCode: referralCode,
      );
    }
  }

  AppAccount _registerUserLocal({
    required String countryCode,
    required String phone,
    required String email,
    required String verificationCode,
    required String password,
    required String displayName,
    String referralCode = '',
  }) {
    if (email.trim().isEmpty) {
      throw StateError(AppStrings.current.errFillEmail);
    }
    if (verificationCode.trim() != '0000') {
      throw StateError(AppStrings.current.errSmsCode0000);
    }
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw StateError(AppStrings.current.errFillPhone);
    }
    final username = '$countryCode$normalizedPhone';
    _ensureUniqueUsername(username);
    final account = AppAccount(
      id: _newId('user'),
      username: username,
      password: password,
      role: AccountRole.user,
      displayName: displayName.trim(),
      phone: username,
      approvalStatus: ApprovalStatus.approved,
      shareCode: _generateUniqueShareCode(),
    );
    accounts.add(account);
    if (referralCode.trim().isNotEmpty) {
      redeemReferralCode(referralCode, forAccount: account);
    }
    notifyListeners();
    return account;
  }

  Future<AppAccount> registerShop({
    required String countryCode,
    required String phone,
    required String email,
    required String verificationCode,
    required String password,
    required String storeName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
    required Set<WashServiceType> serviceTypes,
  }) async {
    if (email.trim().isEmpty) {
      throw StateError(AppStrings.current.errFillEmail);
    }
    if (licenseFiles.isEmpty) {
      throw StateError(AppStrings.current.errUploadLicense);
    }

    if (!_shouldUseBackendApi()) {
      if (verificationCode.trim() != '1111') {
        throw StateError(AppStrings.current.errSmsCode1111);
      }
      return _registerShopLocal(
        countryCode: countryCode,
        phone: phone,
        email: email,
        verificationCode: verificationCode,
        password: password,
        storeName: storeName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        licenseFiles: licenseFiles,
        serviceTypes: serviceTypes,
      );
    }

    try {
      final data = await ApiClient.registerShop(
        countryCode: countryCode,
        phone: phone,
        email: email,
        verificationCode: verificationCode,
        password: password,
        storeName: storeName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        licenseFiles: licenseFiles,
        serviceTypes: serviceTypes.map(_washServiceTypeToApi).toList(),
      );
      final account = _upsertAccountFromApi(data, password: password);
      if (!stores.any((store) => store.ownerAccountId == account.id)) {
        stores.add(
          CarWashStore(
            id: _newId('store'),
            ownerAccountId: account.id,
            name: storeName.trim(),
            address: address.trim(),
            latitude: latitude,
            longitude: longitude,
            rating: 5,
            tags: const ['新入驻'],
            serviceTypes: serviceTypes,
            devices: [
              WashDevice(
                id: _newId('D'),
                qrCode: 'CARWASH-${Random().nextInt(9000) + 1000}',
                bayName: '自助1号',
                status: DeviceStatus.idle,
                lastHeartbeat: DateTime.now(),
              ),
            ],
            packages: defaultPackages,
          ),
        );
      }
      notifyListeners();
      return account;
    } on ApiException {
      rethrow;
    } on ApiConnectionException {
      return _registerShopLocal(
        countryCode: countryCode,
        phone: phone,
        email: email,
        verificationCode: verificationCode,
        password: password,
        storeName: storeName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        licenseFiles: licenseFiles,
        serviceTypes: serviceTypes,
      );
    }
  }

  AppAccount _registerShopLocal({
    required String countryCode,
    required String phone,
    required String email,
    required String verificationCode,
    required String password,
    required String storeName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
    required Set<WashServiceType> serviceTypes,
  }) {
    if (verificationCode.trim() != '1111') {
      throw StateError(AppStrings.current.errSmsCode1111);
    }
    if (licenseFiles.isEmpty) {
      throw StateError(AppStrings.current.errUploadLicense);
    }
    final username = '$countryCode${phone.trim()}';
    _ensureUniqueUsername(username);
    final account = AppAccount(
      id: _newId('shop'),
      username: username,
      password: password,
      role: AccountRole.shop,
      displayName: storeName.trim(),
      phone: username,
      shopAddress: address.trim(),
      shopLatitude: latitude,
      shopLongitude: longitude,
      licenseFiles: licenseFiles,
    );
    accounts.add(account);
    stores.add(
      CarWashStore(
        id: _newId('store'),
        ownerAccountId: account.id,
        name: storeName.trim(),
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        rating: 5,
        tags: const ['新入驻'],
        serviceTypes: serviceTypes,
        devices: [
          WashDevice(
            id: _newId('D'),
            qrCode: 'CARWASH-${Random().nextInt(9000) + 1000}',
            bayName: '自助1号',
            status: DeviceStatus.idle,
            lastHeartbeat: DateTime.now(),
          ),
        ],
        packages: defaultPackages,
      ),
    );
    notifyListeners();
    return account;
  }

  void updateAccountApproval(
    AppAccount account,
    ApprovalStatus status, {
    String adminReply = '',
  }) {
    account.approvalStatus = status;
    if (adminReply.trim().isNotEmpty) {
      account.adminReply = adminReply.trim();
    }
    notifyListeners();
    if (ApiClient.accessToken != null && account.role != AccountRole.admin) {
      unawaited(
        ApiClient.updateApproval(
          accountId: account.id,
          approvalStatus: _approvalStatusToApi(status),
          adminReply: adminReply,
        ).then((json) {
          _applyApiAccount(account, json);
          notifyListeners();
        }).catchError((_) {}),
      );
    }
  }

  void resubmitShopApplication({
    required AppAccount account,
    required String storeName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
    required Set<WashServiceType> serviceTypes,
  }) {
    if (account.role != AccountRole.shop) {
      throw StateError(AppStrings.current.errShopOnlyResubmit);
    }
    if (licenseFiles.isEmpty) {
      throw StateError(AppStrings.current.errUploadLicense);
    }
    account.displayName = storeName.trim();
    account.shopAddress = address.trim();
    account.shopLatitude = latitude;
    account.shopLongitude = longitude;
    account.licenseFiles = [...licenseFiles];
    account.approvalStatus = ApprovalStatus.pending;
    account.adminReply = AppStrings.current.materialsResubmittedAdminReply;
    final store =
        stores.firstWhere((store) => store.ownerAccountId == account.id);
    store.name = storeName.trim();
    store.address = address.trim();
    store.latitude = latitude;
    store.longitude = longitude;
    store.serviceTypes = {...serviceTypes};
    notifyListeners();
  }

  Future<CarWashStore> addStoreForCurrentShop({
    required String storeName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
    required Set<WashServiceType> serviceTypes,
  }) async {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.shop) {
      throw StateError(AppStrings.current.errLoginAsShop);
    }
    if (licenseFiles.isEmpty) {
      throw StateError(AppStrings.current.errUploadLicense);
    }
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final json = await ApiClient.createStore({
        'name': storeName.trim(),
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'service_types': serviceTypes
            .map((t) => t == WashServiceType.manual ? 'manual' : 'selfService')
            .toList(),
      });
      final store = AppSync.storeFromJson(json);
      stores.add(store);
      account.licenseFiles = {...account.licenseFiles, ...licenseFiles}.toList();
      notifyListeners();
      return store;
    }
    final store = CarWashStore(
      id: _newId('store'),
      ownerAccountId: account.id,
      name: storeName.trim(),
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
      rating: 5,
      tags: const ['新店铺'],
      serviceTypes: {...serviceTypes},
      devices: [],
      packages: defaultPackages,
      approvalStatus: ApprovalStatus.pending,
    );
    stores.add(store);
    account.licenseFiles = {...account.licenseFiles, ...licenseFiles}.toList();
    notifyListeners();
    return store;
  }

  Future<void> updateStorePackage({
    required String storeId,
    required String packageId,
    required double price,
    int? minutes,
    String? name,
  }) async {
    final store = storeById(storeId);
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final body = <String, dynamic>{'price': price};
      if (minutes != null) body['minutes'] = minutes;
      if (name != null) body['name'] = name;
      final json = await ApiClient.updatePackage(storeId, packageId, body);
      final updated = AppSync.storeFromJson(json);
      final idx = stores.indexWhere((s) => s.id == storeId);
      if (idx >= 0) stores[idx] = updated;
      notifyListeners();
      return;
    }
    final pkgIdx = store.packages.indexWhere((p) => p.id == packageId);
    if (pkgIdx < 0) {
      throw StateError(AppStrings.current.errPackageNotFound);
    }
    final old = store.packages[pkgIdx];
    store.packages[pkgIdx] = ServicePackage(
      id: old.id,
      name: name ?? old.name,
      minutes: minutes ?? old.minutes,
      price: price,
      description: old.description,
    );
    notifyListeners();
  }

  void updateShopProfile({
    required AppAccount account,
    required String username,
    required String phone,
    required String displayName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
  }) {
    if (account.role != AccountRole.shop) {
      throw StateError(AppStrings.current.errShopOnlyEditProfile);
    }
    if (licenseFiles.isEmpty) {
      throw StateError(AppStrings.current.errUploadLicense);
    }
    final normalizedUsername = username.trim();
    final normalizedPhone = phone.trim();
    if (normalizedUsername.isEmpty ||
        normalizedPhone.isEmpty ||
        displayName.trim().isEmpty ||
        address.trim().isEmpty) {
      throw StateError(AppStrings.current.errFillComplete);
    }
    if (normalizedUsername != account.username) {
      _ensureUniqueUsername(normalizedUsername);
      account.username = normalizedUsername;
    }
    account.phone = normalizedPhone;
    account.displayName = displayName.trim();
    account.shopAddress = address.trim();
    account.shopLatitude = latitude;
    account.shopLongitude = longitude;
    account.licenseFiles = [...licenseFiles];

    final shopStores =
        stores.where((store) => store.ownerAccountId == account.id).toList();
    if (shopStores.isNotEmpty) {
      final primaryStore = shopStores.first;
      primaryStore.name = displayName.trim();
      primaryStore.address = address.trim();
      primaryStore.latitude = latitude;
      primaryStore.longitude = longitude;
    }
    notifyListeners();
  }

  void addDeviceToStore({
    required String storeId,
    required String bayName,
    required WashServiceType serviceType,
  }) {
    final store = storeById(storeId);
    store.serviceTypes.add(serviceType);
    store.devices.add(
      WashDevice(
        id: _newId('D'),
        qrCode: 'CARWASH-${Random().nextInt(9000) + 1000}',
        bayName: bayName.trim(),
        status: DeviceStatus.idle,
        lastHeartbeat: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _ensureUniqueUsername(String username) {
    final normalized = username.trim().toLowerCase();
    final exists = accounts.any(
      (account) => account.username.toLowerCase() == normalized,
    );
    if (exists) {
      throw StateError(AppStrings.current.errAccountExists);
    }
  }

  String _generateUniqueShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    for (var attempt = 0; attempt < 50; attempt++) {
      final code = List.generate(
        8,
        (_) => chars[Random().nextInt(chars.length)],
      ).join();
      if (accountByShareCode(code) == null) {
        return code;
      }
    }
    return 'CW${Random().nextInt(900000 + 100000)}';
  }

  AppAccount? accountByShareCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final account in accounts) {
      if (account.role == AccountRole.user &&
          account.shareCode.toUpperCase() == normalized) {
        return account;
      }
    }
    return null;
  }

  Future<void> redeemReferralCode(String code,
      {required AppAccount forAccount}) async {
    if (forAccount.role != AccountRole.user) {
      throw StateError(AppStrings.current.errUserOnlyReferral);
    }
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final data = await ApiClient.redeemReferral(code);
      _applyApiAccount(forAccount, data);
      final referrerId = data['referrer_id'] as String?;
      if (referrerId != null) {
        final referrerCredits = data['referrer_free_wash_credits'] as int?;
        for (final account in accounts) {
          if (account.id == referrerId) {
            if (referrerCredits != null) {
              account.freeWashCredits = referrerCredits;
            } else {
              account.freeWashCredits += 1;
            }
            if (!account.referredUserIds.contains(forAccount.id)) {
              account.referredUserIds.add(forAccount.id);
            }
            break;
          }
        }
      }
      notifyListeners();
      return;
    }
    if (forAccount.referredByUserId != null) {
      throw StateError(AppStrings.current.errReferralUsed);
    }
    final referrer = accountByShareCode(code);
    if (referrer == null) {
      throw StateError(AppStrings.current.errReferralInvalid);
    }
    if (referrer.id == forAccount.id) {
      throw StateError(AppStrings.current.errReferralSelf);
    }
    forAccount.referredByUserId = referrer.id;
    referrer.referredUserIds.add(forAccount.id);
    forAccount.freeWashCredits += 1;
    referrer.freeWashCredits += 1;
    notifyListeners();
  }

  int completedWashCount(String userAccountId) {
    return orders
        .where(
          (order) =>
              order.userAccountId == userAccountId &&
              order.status == OrderStatus.completed,
        )
        .length;
  }

  bool canShareReferral(AppAccount account) {
    return account.role == AccountRole.user &&
        completedWashCount(account.id) > 0;
  }

  int freeWashUsedCount(String userAccountId) {
    return orders
        .where(
          (order) =>
              order.userAccountId == userAccountId &&
              order.usedFreeWashCredit,
        )
        .length;
  }

  void setAutoUseFreeWash(bool value) {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.user) {
      return;
    }
    account.autoUseFreeWash = value;
    notifyListeners();
  }

  WashOrder? get runningOrder {
    for (final order in orders) {
      if (order.status == OrderStatus.running ||
          order.status == OrderStatus.starting ||
          order.status == OrderStatus.paid) {
        return order;
      }
    }
    return null;
  }

  List<CarWashStore> storesForCurrentShop() {
    final account = currentAccount;
    if (account == null) {
      return [];
    }
    return stores
        .where((store) => store.ownerAccountId == account.id)
        .toList(growable: false);
  }

  List<CarWashStore> approvedStores() {
    final cached = _approvedStoresCache;
    if (cached != null) {
      return cached;
    }
    final computed = stores.where((store) {
      final owner = accountById(store.ownerAccountId);
      return owner.approvalStatus == ApprovalStatus.approved &&
          store.approvalStatus == ApprovalStatus.approved;
    }).toList(growable: false);
    _approvedStoresCache = computed;
    return computed;
  }

  HkMajorRegion? majorRegionForStore(CarWashStore store) {
    return hkMajorRegionForAddress(store.address);
  }

  List<CarWashStore> approvedStoresInRegion(HkMajorRegion region) {
    return approvedStores()
        .where((store) => majorRegionForStore(store) == region)
        .toList(growable: false);
  }

  List<CarWashStore> approvedStoresForScanContext({
    CarWashStore? anchorStore,
  }) {
    if (anchorStore == null) {
      return approvedStores();
    }
    final region = majorRegionForStore(anchorStore);
    if (region == null) {
      return approvedStores()
          .where((store) => store.id == anchorStore.id)
          .toList(growable: false);
    }
    final regional = approvedStoresInRegion(region);
    if (regional.isEmpty) {
      return [anchorStore];
    }
    return regional;
  }

  List<Reservation> reservationsForCurrentShop() {
    final shopStoreIds =
        storesForCurrentShop().map((store) => store.id).toSet();
    return reservations
        .where((reservation) => shopStoreIds.contains(reservation.storeId))
        .toList(growable: false);
  }

  List<WashOrder> ordersForCurrentShop() {
    final shopStoreIds =
        storesForCurrentShop().map((store) => store.id).toSet();
    return orders
        .where((order) => shopStoreIds.contains(order.storeId))
        .toList(growable: false);
  }

  double receivedRevenueForCurrentShop({String? storeId}) {
    return ordersForCurrentShop().where((order) {
      if (storeId != null && order.storeId != storeId) {
        return false;
      }
      if (order.paidAt == null || order.usedFreeWashCredit) {
        return false;
      }
      return order.status != OrderStatus.created &&
          order.status != OrderStatus.failed &&
          order.status != OrderStatus.refunded;
    }).fold<double>(0, (sum, order) => sum + order.amount);
  }

  int pendingPaymentCountForCurrentShop({String? storeId}) {
    return ordersForCurrentShop()
        .where(
          (order) =>
              order.status == OrderStatus.created &&
              (storeId == null || order.storeId == storeId),
        )
        .length;
  }

  int paidOrderCountForCurrentShop({String? storeId}) {
    return ordersForCurrentShop()
        .where(
          (order) =>
              order.paidAt != null &&
              (storeId == null || order.storeId == storeId),
        )
        .length;
  }

  int get idleDeviceCount =>
      devices.where((device) => device.status == DeviceStatus.idle).length;

  int get alertDeviceCount => devices
      .where(
        (device) =>
            device.status == DeviceStatus.offline ||
            device.status == DeviceStatus.faulted,
      )
      .length;

  double get todayRevenue {
    final today = DateTime.now();
    bool isToday(DateTime? time) {
      if (time == null) {
        return false;
      }
      return time.year == today.year &&
          time.month == today.month &&
          time.day == today.day;
    }

    return orders
        .where(
          (order) =>
              order.status == OrderStatus.completed && isToday(order.finishedAt),
        )
        .fold<double>(0, (sum, order) => sum + order.amount);
  }

  int get todayCompletedOrderCount {
    final today = DateTime.now();
    bool isToday(DateTime? time) {
      if (time == null) {
        return false;
      }
      return time.year == today.year &&
          time.month == today.month &&
          time.day == today.day;
    }

    return orders
        .where(
          (order) =>
              order.status == OrderStatus.completed && isToday(order.finishedAt),
        )
        .length;
  }

  double shopWalletBalance(String shopAccountId) =>
      shopWalletBalances[shopAccountId] ?? 0;

  List<UserVehicle> vehiclesForUser(String userAccountId) =>
      userVehicles[userAccountId] ?? [];

  List<UserAddress> addressesForUser(String userAccountId) =>
      userAddresses[userAccountId] ?? [];

  Future<UserVehicle> addVehicle({
    required String userAccountId,
    required String plate,
    required String model,
    String color = '',
  }) async {
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final json = await ApiClient.createVehicle({
        'plate': plate.trim(),
        'model': model.trim(),
        'color': color.trim(),
      });
      final vehicle = AppSync.vehicleFromJson(json);
      userVehicles.putIfAbsent(userAccountId, () => []).add(vehicle);
      notifyListeners();
      return vehicle;
    }
    final vehicle = UserVehicle(
      id: _newId('vehicle'),
      plate: plate.trim(),
      model: model.trim(),
      color: color.trim(),
    );
    userVehicles.putIfAbsent(userAccountId, () => []).add(vehicle);
    notifyListeners();
    return vehicle;
  }

  Future<UserAddress> addAddress({
    required String userAccountId,
    required String label,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final json = await ApiClient.createAddress({
        'label': label.trim(),
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
      });
      final item = AppSync.addressFromJson(json);
      userAddresses.putIfAbsent(userAccountId, () => []).add(item);
      notifyListeners();
      return item;
    }
    final item = UserAddress(
      id: _newId('addr'),
      label: label.trim(),
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
    );
    userAddresses.putIfAbsent(userAccountId, () => []).add(item);
    notifyListeners();
    return item;
  }

  Future<bool> withdrawShopWallet(double amount) async {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.shop) {
      throw StateError(AppStrings.current.errLoginAsShopMerchant);
    }
    if (amount <= 0) {
      throw StateError(AppStrings.current.errWithdrawPositive);
    }
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final wallet = await ApiClient.withdrawWallet(amount);
      shopWalletBalances[account.id] =
          (wallet['balance'] as num?)?.toDouble() ?? 0;
      walletTransactions
        ..clear()
        ..addAll(
          (wallet['transactions'] as List<dynamic>? ?? [])
              .map(
                (item) => AppSync.walletTxnFromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
      notifyListeners();
      return true;
    }
    final balance = shopWalletBalance(account.id);
    if (amount > balance) {
      throw StateError(AppStrings.current.errInsufficientBalance);
    }
    shopWalletBalances[account.id] = balance - amount;
    walletTransactions.insert(
      0,
      WalletTransaction(
        id: _newId('txn'),
        title: AppStrings.current.withdrawToAlipay,
        amount: -amount,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  Iterable<WashDevice> get devices sync* {
    for (final store in stores) {
      yield* store.devices;
    }
  }

  CarWashStore storeById(String id) {
    return stores.firstWhere((store) => store.id == id);
  }

  AppAccount accountById(String id) {
    return accounts.firstWhere((account) => account.id == id);
  }

  WashDevice deviceById(String id) {
    return devices.firstWhere((device) => device.id == id);
  }

  ServicePackage packageById(String storeId, String packageId) {
    return storeById(
      storeId,
    ).packages.firstWhere((washPackage) => washPackage.id == packageId);
  }

  WashDevice? deviceByQr(String qrCode) {
    final normalized = qrCode.trim().toUpperCase();
    for (final device in devices) {
      if (device.qrCode.toUpperCase() == normalized) {
        return device;
      }
    }
    return null;
  }

  CarWashStore? storeForDevice(String deviceId) {
    for (final store in stores) {
      if (store.devices.any((device) => device.id == deviceId)) {
        return store;
      }
    }
    return null;
  }

  Future<WashOrder> createPendingOrder({
    required String deviceQrCode,
    required String packageId,
    bool useFreeWash = false,
    bool usePrepaidWash = false,
  }) async {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.user) {
      throw StateError(AppStrings.current.errLoginAsUser);
    }
    final device = deviceByQr(deviceQrCode);
    if (device == null) {
      throw StateError(AppStrings.current.errDeviceQrNotFound);
    }
    if (device.status != DeviceStatus.idle) {
      throw StateError(AppStrings.current.errDeviceUnavailable);
    }
    if (useFreeWash && usePrepaidWash) {
      throw StateError(AppStrings.current.errCannotUseBothCredits);
    }

    final store = storeForDevice(device.id)!;
    final washPackage = packageById(store.id, packageId);

    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      try {
        final json = await ApiClient.createOrder({
          'store_id': store.id,
          'device_id': device.id,
          'package_id': washPackage.id,
          'amount': washPackage.price,
          'used_free_wash_credit': useFreeWash,
          'used_prepaid_wash_credit': usePrepaidWash,
        });
        final order = AppSync.orderFromJson(json);
        account.freeWashCredits =
            json['free_wash_credits'] as int? ?? account.freeWashCredits;
        account.prepaidWashCredits =
            json['prepaid_wash_credits'] as int? ?? account.prepaidWashCredits;
        orders.insert(0, order);
        _touchCatalog();
        notifyListeners();
        return order;
      } on ApiConnectionException {
        // Fall back to local order flow when backend is unreachable.
      } on ApiException catch (exception) {
        if (exception.statusCode != 405 && exception.statusCode != 404) {
          rethrow;
        }
        // Fall back when backend route is missing or unsupported.
      }
    }

    if (useFreeWash && account.freeWashCredits <= 0) {
      throw StateError(AppStrings.current.errNoFreeWash);
    }
    if (usePrepaidWash && account.prepaidWashCredits <= 0) {
      throw StateError(AppStrings.current.errNoPrepaidWash);
    }
    if (useFreeWash) account.freeWashCredits -= 1;
    if (usePrepaidWash) account.prepaidWashCredits -= 1;
    final useCredit = useFreeWash || usePrepaidWash;
    final order = WashOrder(
      id: _newId('CW'),
      userAccountId: account.id,
      storeId: store.id,
      deviceId: device.id,
      packageId: washPackage.id,
      status: OrderStatus.created,
      amount: useCredit ? 0 : washPackage.price,
      createdAt: DateTime.now(),
      remainingSeconds: washPackage.minutes * 60,
      usedFreeWashCredit: useFreeWash,
    );
    orders.insert(0, order);
    _touchCatalog();
    notifyListeners();
    return order;
  }

  Future<void> markOrderPaid(
    String orderId, {
    required String transactionId,
    required String paymentMethod,
    String? providerReference,
  }) async {
    final order = orders.firstWhere(
      (candidate) => candidate.id == orderId,
      orElse: () => throw StateError(AppStrings.current.errOrderNotFound),
    );
    if (order.status == OrderStatus.paid) {
      return;
    }
    if (order.status != OrderStatus.created) {
      throw StateError(AppStrings.current.errOrderNotPayable);
    }

    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      try {
        final json = await ApiClient.updateOrder(orderId, {
          'status': 'paid',
          'payment_transaction_id': transactionId,
          'payment_method': paymentMethod,
          if (providerReference != null)
            'provider_reference': providerReference,
        });
        final updated = AppSync.orderFromJson(json);
        final idx = orders.indexWhere((candidate) => candidate.id == orderId);
        if (idx >= 0) {
          orders[idx] = updated;
        }
        notifyListeners();
        return;
      } on ApiConnectionException {
        // Fall back to local state when backend is unreachable.
      }
    }

    order.status = OrderStatus.paid;
    order.paymentTransactionId = transactionId;
    order.paymentMethod = paymentMethod;
    order.providerReference = providerReference;
    order.paidAt = DateTime.now();
    notifyListeners();
  }

  Future<void> startOrder(WashOrder order) async {
    if (order.status != OrderStatus.paid) {
      return;
    }

    final device = deviceById(order.deviceId);
    order.status = OrderStatus.starting;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (device.status != DeviceStatus.idle) {
      order.status = OrderStatus.failed;
      order.failureReason = AppStrings.current.errDeviceNotIdle;
      notifyListeners();
      return;
    }

    device.status = DeviceStatus.busy;
    device.lastHeartbeat = DateTime.now();
    device.useCount += 1;
    order.status = OrderStatus.running;
    order.startedAt = DateTime.now();
    notifyListeners();
    _startTimer();
  }

  Future<void> simulatePaymentAndStart(WashOrder order) async {
    if (order.status != OrderStatus.created) {
      return;
    }
    order.status = OrderStatus.paid;
    notifyListeners();
    await startOrder(order);
  }

  void finishOrder(WashOrder order) {
    if (order.status != OrderStatus.running &&
        order.status != OrderStatus.starting) {
      return;
    }
    order.status = OrderStatus.completed;
    order.finishedAt = DateTime.now();
    order.remainingSeconds = 0;
    final device = deviceById(order.deviceId);
    if (order.startedAt != null) {
      device.totalUseSeconds +=
          DateTime.now().difference(order.startedAt!).inSeconds;
    }
    device.status = DeviceStatus.idle;
    device.lastHeartbeat = DateTime.now();
    notifyListeners();
  }

  Future<Reservation> createReservation({
    required String storeId,
    required WashServiceType serviceType,
    required LatLng userLocation,
    required DateTime arrivalTime,
    required String contactPhone,
    required String note,
  }) async {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.user) {
      throw StateError(AppStrings.current.errLoginAsUser);
    }
    final store = storeById(storeId);
    if (!store.serviceTypes.contains(serviceType)) {
      throw StateError(AppStrings.current.errServiceTypeUnsupported);
    }
    if (contactPhone.trim().isEmpty) {
      throw StateError(AppStrings.current.errFillContactPhone);
    }
    final distanceKm = distanceBetweenKm(userLocation, store.position);
    final etaMinutes = estimateEtaMinutes(distanceKm);
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final json = await ApiClient.createReservation({
        'store_id': storeId,
        'service_type': serviceType == WashServiceType.manual
            ? 'manual'
            : 'selfService',
        'user_latitude': userLocation.latitude,
        'user_longitude': userLocation.longitude,
        'distance_km': distanceKm,
        'eta_minutes': etaMinutes,
        'arrival_time': arrivalTime.toUtc().toIso8601String(),
        'contact_phone': contactPhone.trim(),
        'note': note.trim(),
      });
      final reservation = AppSync.reservationFromJson(json);
      reservations.insert(0, reservation);
      lastReservationPhone = contactPhone.trim();
      notifyListeners();
      return reservation;
    }
    final reservation = Reservation(
      id: _newId('R'),
      userAccountId: account.id,
      storeId: storeId,
      serviceType: serviceType,
      userLocation: userLocation,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      arrivalTime: arrivalTime,
      contactPhone: contactPhone.trim(),
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    lastReservationPhone = contactPhone.trim();
    reservations.insert(0, reservation);
    notifyListeners();
    return reservation;
  }

  Future<void> updateReservationStatus(
    Reservation reservation,
    ReservationStatus status,
  ) async {
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final json = await ApiClient.updateReservation(reservation.id, {
        'status': status.name,
      });
      final index = reservations.indexWhere((item) => item.id == reservation.id);
      if (index >= 0) {
        reservations[index] = AppSync.reservationFromJson(json);
      }
      notifyListeners();
      return;
    }
    reservation.status = status;
    notifyListeners();
  }

  void markDeviceStatus(String deviceId, DeviceStatus status) {
    final device = deviceById(deviceId);
    if (status == DeviceStatus.faulted &&
        device.status != DeviceStatus.faulted) {
      device.faultCount += 1;
    }
    device.status = status;
    device.lastHeartbeat = DateTime.now();
    notifyListeners();
  }

  void _startTimer() {
    _washTimer?.cancel();
    _washTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final order = runningOrder;
      if (order == null || order.status != OrderStatus.running) {
        _washTimer?.cancel();
        return;
      }
      order.remainingSeconds -= 1;
      deviceById(order.deviceId).lastHeartbeat = DateTime.now();
      if (order.remainingSeconds <= 0) {
        finishOrder(order);
      } else {
        orderTick.value++;
      }
    });
  }

  @override
  void dispose() {
    _washTimer?.cancel();
    orderTick.dispose();
    catalogTick.dispose();
    syncUi.dispose();
    super.dispose();
  }

  static List<AppAccount> _seedAccounts() {
    return [
      AppAccount(
        id: 'user-demo',
        username: 'user',
        password: '123456',
        role: AccountRole.user,
        displayName: '演示用户',
        phone: '13800000001',
        approvalStatus: ApprovalStatus.approved,
        shareCode: 'DEMOCW01',
      ),
      AppAccount(
        id: 'shop-demo',
        username: 'shop',
        password: '123456',
        role: AccountRole.shop,
        displayName: '蓝鲸运营',
        phone: '13800000002',
        approvalStatus: ApprovalStatus.approved,
        shopAddress: '香港港岛中西区干诺道中 88 号',
        shopLatitude: 22.2819,
        shopLongitude: 114.1589,
        licenseFiles: const ['blue-whale-license.pdf'],
      ),
      AppAccount(
        id: 'admin-demo',
        username: 'admin',
        password: '123456',
        role: AccountRole.admin,
        displayName: '平台管理员',
        phone: '13800000000',
        approvalStatus: ApprovalStatus.approved,
      ),
    ];
  }

  static List<CarWashStore> _seedStores() {
    return [
      CarWashStore(
        id: 'store-1',
        ownerAccountId: 'shop-demo',
        name: '蓝鲸自助洗车 中环店',
        address: '香港港岛中西区干诺道中 88 号',
        latitude: 22.2819,
        longitude: 114.1589,
        rating: 4.8,
        tags: const ['24小时', '自助', '空闲多'],
        serviceTypes: const {WashServiceType.selfService},
        packages: defaultPackages,
        devices: [
          WashDevice(
            id: 'D-1001',
            qrCode: 'CARWASH-1001',
            bayName: '自助1号',
            status: DeviceStatus.idle,
            lastHeartbeat: DateTime.now(),
          ),
          WashDevice(
            id: 'D-1002',
            qrCode: 'CARWASH-1002',
            bayName: '自助2号',
            status: DeviceStatus.busy,
            lastHeartbeat: DateTime.now().subtract(const Duration(seconds: 9)),
          ),
          WashDevice(
            id: 'D-1003',
            qrCode: 'CARWASH-1003',
            bayName: '自助3号',
            status: DeviceStatus.idle,
            lastHeartbeat: DateTime.now(),
          ),
        ],
      ),
      CarWashStore(
        id: 'store-2',
        ownerAccountId: 'shop-demo',
        name: '净驰洗车 观塘店',
        address: '香港九龙观塘区成业街 21 号',
        latitude: 22.3114,
        longitude: 114.2260,
        rating: 4.6,
        tags: const ['人工精洗', '自助吸尘'],
        serviceTypes: const {
          WashServiceType.selfService,
          WashServiceType.manual
        },
        packages: defaultPackages,
        devices: [
          WashDevice(
            id: 'D-2001',
            qrCode: 'CARWASH-2001',
            bayName: '自助A工位',
            status: DeviceStatus.idle,
            lastHeartbeat: DateTime.now(),
          ),
          WashDevice(
            id: 'D-2002',
            qrCode: 'CARWASH-2002',
            bayName: '自助B工位',
            status: DeviceStatus.faulted,
            lastHeartbeat: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
      ),
      CarWashStore(
        id: 'store-3',
        ownerAccountId: 'shop-demo',
        name: '驿站人工洗车 沙田店',
        address: '香港新界沙田区沙田正街 3 号',
        latitude: 22.3875,
        longitude: 114.1953,
        rating: 4.5,
        tags: const ['人工洗车', '商场停车场'],
        serviceTypes: const {WashServiceType.manual},
        packages: defaultPackages,
        devices: [
          WashDevice(
            id: 'D-3001',
            qrCode: 'CARWASH-3001',
            bayName: '人工接待位',
            status: DeviceStatus.offline,
            lastHeartbeat: DateTime.now().subtract(const Duration(minutes: 17)),
          ),
        ],
      ),
    ];
  }

  static List<WashOrder> _seedOrders() {
    return [
      WashOrder(
        id: 'CW-DEMO-1',
        userAccountId: 'user-demo',
        storeId: 'store-1',
        deviceId: 'D-1001',
        packageId: 'basic',
        status: OrderStatus.completed,
        amount: 28,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        finishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  static Map<String, List<UserVehicle>> _seedUserVehicles() {
    return {
      'user-demo': [
        UserVehicle(
          id: 'vehicle-1',
          plate: '粤B·88888',
          model: '宝马 i3',
          color: '白色',
        ),
      ],
    };
  }

  static Map<String, List<UserAddress>> _seedUserAddresses() {
    return {
      'user-demo': [
        UserAddress(
          id: 'addr-1',
          label: '家',
          address: '香港中西区皇后大道中 100 号',
        ),
      ],
    };
  }

  static List<WalletTransaction> _seedWalletTransactions() {
    return [
      WalletTransaction(
        id: 'txn-1',
        title: '标准自助洗 · 粤B·88888',
        amount: 15.3,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        orderId: 'CW-DEMO-1',
      ),
    ];
  }
}

const defaultPackages = [
  ServicePackage(
    id: 'quick',
    name: '快速冲洗',
    minutes: 8,
    price: 12,
    description: '适合轻度灰尘快速清洁',
  ),
  ServicePackage(
    id: 'basic',
    name: '标准自助洗',
    minutes: 12,
    price: 18,
    description: '高压水枪、泡沫、清水冲洗',
  ),
  ServicePackage(
    id: 'premium',
    name: '精洗套餐',
    minutes: 20,
    price: 32,
    description: '含泡沫、镀膜水蜡和吸尘',
  ),
];

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final account = store.currentAccount;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: appTabTransitionBuilder,
          child: account == null
              ? const AuthPage(key: ValueKey('auth'))
              : switch (account.role) {
                  AccountRole.user => const UserShell(key: ValueKey('user-shell')),
                  AccountRole.shop =>
                    account.approvalStatus == ApprovalStatus.approved
                        ? const ShopShell(key: ValueKey('shop-shell'))
                        : const ShopReviewPage(key: ValueKey('shop-review')),
                  AccountRole.admin =>
                    const AdminShell(key: ValueKey('admin-shell')),
                },
        );
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final usernameController = TextEditingController(text: 'user');
  final passwordController = TextEditingController(text: '123456');
  String countryCode = '+86';
  String? error;
  bool isLoggingIn = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.background],
            stops: [0.0, 0.42],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                children: [
                  const Center(child: AppBrandLogo(size: 84)),
              const SizedBox(height: 16),
              Text(
                context.s.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.s.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
              ),
              const SizedBox(height: 24),
              AppFadeSlideIn(
                child: Container(
                padding: const EdgeInsets.all(22),
                decoration: appSurfaceCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.s.welcomeLogin,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.s.loginRoleHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 148,
                          child: CountryCodeDropdown(
                            value: countryCode,
                            onChanged: (value) =>
                                setState(() => countryCode = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: usernameController,
                            decoration: InputDecoration(labelText: context.s.phoneOrTestAccount,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.s.phoneLoginHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: context.s.password),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: isLoggingIn
                          ? null
                          : () async {
                              setState(() {
                                isLoggingIn = true;
                                error = null;
                              });
                              try {
                                final ok = await store.login(
                                  _loginUsername(),
                                  passwordController.text,
                                );
                                if (!ok && mounted) {
                                  setState(() => error =
                                      store.lastAuthMessage ?? context.s.accountMismatch);
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => isLoggingIn = false);
                                }
                              }
                            },
                      child: isLoggingIn
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.s.login),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterUserPage(),
                              ),
                            ),
                            child: Text(context.s.userRegister),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterShopPage(),
                              ),
                            ),
                            child: Text(context.s.shopRegister),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 16),
              const DemoCredentialCard(),
                ],
              ),
              const Positioned(
                top: 8,
                right: 8,
                child: LanguageSwitcher(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _loginUsername() {
    final input = usernameController.text.trim();
    if (input == 'user' || input == 'shop' || input == 'admin') {
      return input;
    }
    if (input.startsWith('+')) {
      return input;
    }
    return '$countryCode$input';
  }
}

class DemoCredentialCard extends StatelessWidget {
  const DemoCredentialCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(icon: Icons.key_rounded, size: 36),
              const SizedBox(width: 10),
              Text(
                s.demoAccounts,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('User: user / 123456'),
          const Text('Shop: shop / 123456'),
          const Text('Admin: admin / 123456'),
        ],
      ),
    );
  }
}

class CountryCodeDropdown extends StatelessWidget {
  const CountryCodeDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<CountryCallingCode>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CountryCodePickerSheet(),
    );
    if (selected != null) {
      onChanged(selected.dialCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context).appLocale;
    final selected = countryCallingCodeForDialCode(value);
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(labelText: context.s.countryCodeLabel,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selected.displayLabelFor(locale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _CountryCodePickerSheet extends StatefulWidget {
  const _CountryCodePickerSheet();

  @override
  State<_CountryCodePickerSheet> createState() =>
      _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<_CountryCodePickerSheet> {
  final searchController = TextEditingController();
  final filterTick = ValueNotifier<int>(0);

  @override
  void dispose() {
    searchController.dispose();
    filterTick.dispose();
    super.dispose();
  }

  void _notifyFilterChanged() {
    filterTick.value++;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  enableIMEPersonalizedLearning: true,
                  decoration: InputDecoration(
                    hintText: context.s.searchCountryHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ValueListenableBuilder<int>(
                      valueListenable: filterTick,
                      builder: (context, _, __) {
                        if (searchController.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          onPressed: () {
                            searchController.clear();
                            _notifyFilterChanged();
                          },
                          icon: const Icon(Icons.clear),
                        );
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _notifyFilterChanged(),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: filterTick,
                builder: (context, _, __) {
                  final filteredCodes =
                      filterCountryCallingCodes(searchController.text);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.s.countryRegionCount(filteredCodes.length),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: filterTick,
                  builder: (context, _, __) {
                    final filteredCodes =
                        filterCountryCallingCodes(searchController.text);
                    if (filteredCodes.isEmpty) {
                      return Center(child: Text(context.s.noDialCodeMatch));
                    }
                    final locale = LocaleScope.of(context).appLocale;
                    return ListView.builder(
                      itemCount: filteredCodes.length,
                      itemBuilder: (context, index) {
                        final country = filteredCodes[index];
                        final secondaryName = locale == AppLocale.en
                            ? country.nameZh
                            : country.nameEn;
                        return ListTile(
                          title: Text(country.localizedName(locale)),
                          subtitle: Text(secondaryName),
                          trailing: Text(
                            country.dialCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, country),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopReviewPage extends StatefulWidget {
  const ShopReviewPage({super.key});

  @override
  State<ShopReviewPage> createState() => _ShopReviewPageState();
}

class _ShopReviewPageState extends State<ShopReviewPage> {
  final storeNameController = TextEditingController();
  final addressController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final serviceTypes = <WashServiceType>{};
  final licenseFiles = <String>[];
  bool initialized = false;
  String? error;
  bool geocoding = false;
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
    final store = AppScope.of(context).stores.firstWhere(
          (store) => store.ownerAccountId == account.id,
        );
    storeNameController.text = store.name;
    addressController.text = store.address;
    latController.text = store.latitude.toStringAsFixed(6);
    lngController.text = store.longitude.toStringAsFixed(6);
    serviceTypes
      ..clear()
      ..addAll(store.serviceTypes);
    licenseFiles
      ..clear()
      ..addAll(account.licenseFiles);
    initialized = true;
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    addressController.removeListener(_scheduleGeocode);
    storeNameController.dispose();
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
        geocodingMessage = result.formattedAddress == null
            ? context.s.geocodeCoordsUpdated
            : context.s.geocodeLocated(result.formattedAddress!);
      });
    } on GeocodingException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => geocodingMessage = exception.message);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => geocodingMessage = context.s.geocodeFailedMsg(error));
    } finally {
      if (mounted) {
        setState(() => geocoding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.shopRegReviewTitle),
        actions: [
          IconButton(
              onPressed: appStore.logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatusPill(
            text: account.approvalStatus.label,
            color: account.approvalStatus.color,
          ),
          const SizedBox(height: 12),
          Text(context.s.loginAccountLine(account.username)),
          if (account.adminReply.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(context.s.adminReplyLine(account.adminReply)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppTextField(controller: storeNameController, label: context.s.merchantName),
          AppTextField(controller: addressController, label: context.s.merchantAddress),
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
                  child: AppTextField(controller: latController, label: context.s.latitude)),
              const SizedBox(width: 12),
              Expanded(
                  child: AppTextField(controller: lngController, label: context.s.longitude)),
            ],
          ),
          Text(context.s.merchantLicensePermit, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LicenseUploadSection(
            files: licenseFiles,
            onChanged: (files) => setState(() {
              licenseFiles
                ..clear()
                ..addAll(files);
              error = null;
            }),
          ),
          const SizedBox(height: 8),
          Text(context.s.serviceTypes, style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final type in sortedWashServiceTypes(serviceTypes))
            CheckboxListTile(
              value: serviceTypes.contains(type),
              onChanged: (value) => setState(() {
                _toggleService(type, value ?? false);
              }),
              title: Text(type.label),
              subtitle: washServiceTypeSubtitle(type),
              secondary: Icon(type.icon),
            ),
          if (serviceTypes.contains(WashServiceType.selfService))
            const SelfServiceEcoBanner(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          FilledButton.icon(
            onPressed: _resubmit,
            icon: const Icon(Icons.upload_file),
            label: Text(context.s.resubmitForReview),
          ),
        ],
      ),
    );
  }

  void _toggleService(WashServiceType type, bool selected) {
    if (selected) {
      serviceTypes.add(type);
    } else {
      serviceTypes.remove(type);
    }
  }

  void _resubmit() {
    try {
      _validateRequired([
        storeNameController.text,
        addressController.text,
        latController.text,
        lngController.text,
      ]);
      if (licenseFiles.isEmpty) {
        throw StateError(context.s.errUploadLicense);
      }
      if (serviceTypes.isEmpty) {
        throw StateError(context.s.errSelectOneService);
      }
      final latitude = double.tryParse(latController.text.trim());
      final longitude = double.tryParse(lngController.text.trim());
      if (latitude == null || longitude == null) {
        throw StateError(context.s.errInvalidLatLng);
      }
      final appStore = AppScope.of(context);
      appStore.resubmitShopApplication(
        account: appStore.currentAccount!,
        storeName: storeNameController.text,
        address: addressController.text,
        latitude: latitude,
        longitude: longitude,
        licenseFiles: licenseFiles,
        serviceTypes: serviceTypes,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.materialsResubmittedWait)),
      );
    } on Object catch (exception) {
      setState(
          () => error = exception.toString().replaceFirst('Bad state: ', ''));
    }
  }
}

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final verificationController = TextEditingController();
  final passwordController = TextEditingController();
  final referralController = TextEditingController();
  String countryCode = '+86';
  String? error;
  int _codeCooldown = 0;
  Timer? _codeTimer;

  @override
  void dispose() {
    _codeTimer?.cancel();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    verificationController.dispose();
    passwordController.dispose();
    referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.s.userRegister)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: nameController, label: context.s.fullNameLabel),
          AppTextField(
            controller: emailController,
            label: context.s.emailLabel,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 148,
                child: CountryCodeDropdown(
                  value: countryCode,
                  onChanged: (value) => setState(() => countryCode = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      AppTextField(controller: phoneController, label: context.s.phone)),
            ],
          ),
          AppTextField(
              controller: verificationController,
              label: context.s.emailVerificationCode),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _codeCooldown > 0 ? null : _sendEmailCode,
              child: Text(_codeCooldown > 0
                  ? context.s.smsResendIn(_codeCooldown)
                  : context.s.getVerificationCode),
            ),
          ),
          AppTextField(
            controller: passwordController,
            label: context.s.password,
            obscureText: true,
          ),
          AppTextField(
            controller: referralController,
            label: context.s.referralCodeOptional,
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: () async {
              try {
                _validateRequired([
                  nameController.text,
                  emailController.text,
                  phoneController.text,
                  verificationController.text,
                  passwordController.text,
                ]);
                await store.registerUser(
                  countryCode: countryCode,
                  phone: phoneController.text,
                  email: emailController.text,
                  verificationCode: verificationController.text,
                  password: passwordController.text,
                  displayName: nameController.text,
                  referralCode: referralController.text,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        context.s.userRegisterSuccess('$countryCode${phoneController.text.trim()}')),
                  ),
                );
              } on Object catch (exception) {
                setState(() => error =
                    exception.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: Text(context.s.registerLogin),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmailCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => error = context.s.fillEmailFirst);
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => error = context.s.invalidEmailFormat);
      return;
    }
    try {
      await ApiClient.sendEmailCode(
        email: email,
        purpose: 'register_user',
      );
      setState(() {
        error = null;
        _codeCooldown = 60;
      });
      _codeTimer?.cancel();
      _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_codeCooldown <= 1) {
          timer.cancel();
          if (mounted) setState(() => _codeCooldown = 0);
        } else if (mounted) {
          setState(() => _codeCooldown -= 1);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.emailCodeSent)),
        );
      }
    } on Object catch (e) {
      setState(() => error = e.toString());
    }
  }
}

class RegisterShopPage extends StatefulWidget {
  const RegisterShopPage({super.key});

  @override
  State<RegisterShopPage> createState() => _RegisterShopPageState();
}

class _RegisterShopPageState extends State<RegisterShopPage> {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final verificationController = TextEditingController();
  final passwordController = TextEditingController();
  final storeNameController = TextEditingController();
  final addressDetailController = TextEditingController();
  final licenseFiles = <String>[];
  final serviceTypes = <WashServiceType>{
    WashServiceType.selfService,
    WashServiceType.manual,
  };
  String countryCode = '+852';
  HkMajorRegion majorRegion = HkMajorRegion.hongKongIsland;
  HkDistrict selectedDistrict = kHkDistricts.first;
  HkSubArea selectedSubArea = kHkSubAreas.first;
  final GlobalKey<CarWashMapViewState> shopMapKey = GlobalKey<CarWashMapViewState>();
  String? error;
  bool submitting = false;
  LatLng? geocodedLocation;
  String? geocodedAddress;
  bool geocoding = false;
  String? geocodingMessage;
  Timer? _geocodeDebounce;
  int _codeCooldown = 0;
  Timer? _codeTimer;

  @override
  void initState() {
    super.initState();
    addressDetailController.addListener(_scheduleGeocode);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleGeocode());
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _codeTimer?.cancel();
    addressDetailController.removeListener(_scheduleGeocode);
    emailController.dispose();
    phoneController.dispose();
    verificationController.dispose();
    passwordController.dispose();
    storeNameController.dispose();
    addressDetailController.dispose();
    super.dispose();
  }

  LatLng get fallbackLocation => latLngForHkSelection(
        district: selectedDistrict,
        subArea: selectedSubArea,
      );

  LatLng get mapLocation => geocodedLocation ?? fallbackLocation;

  String get fullAddress => buildHkShopAddress(
        district: selectedDistrict,
        subArea: selectedSubArea,
        detail: addressDetailController.text,
      );

  String get locationLabel => buildHkLocationLabel(
        majorRegion: majorRegion,
        district: selectedDistrict,
        subArea: selectedSubArea,
      );

  void _syncMapCamera() {
    shopMapKey.currentState?.moveCamera(mapLocation, zoom: geocodedLocation == null ? 14 : 16);
  }

  void _scheduleGeocode() {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_geocodeAddress());
    });
  }

  Future<void> _geocodeAddress() async {
    final address = fullAddress;
    if (address.trim().isEmpty) {
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
        geocodedLocation = result.position;
        geocodedAddress = result.formattedAddress;
        geocodingMessage = result.formattedAddress == null
            ? context.s.addressGeocodedOk
            : context.s.geocodeLocated(result.formattedAddress!);
      });
      await shopMapKey.currentState?.moveCamera(result.position, zoom: 16);
    } on GeocodingException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() {
        geocodedLocation = null;
        geocodedAddress = null;
        geocodingMessage = context.s.geocodeSubAreaFallback(
            exception.message, selectedSubArea.nameZh);
      });
      _syncMapCamera();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        geocodedLocation = null;
        geocodedAddress = null;
        geocodingMessage = context.s.geocodeAreaFallback(error);
      });
      _syncMapCamera();
    } finally {
      if (mounted) {
        setState(() => geocoding = false);
      }
    }
  }

  void _onMajorRegionChanged(HkMajorRegion region) {
    final districts = hkDistrictsForRegion(region);
    final district = districts.first;
    final subAreas = hkSubAreasForDistrict(district.nameZh);
    setState(() {
      majorRegion = region;
      selectedDistrict = district;
      selectedSubArea = subAreas.first;
    });
    _scheduleGeocode();
  }

  void _onDistrictChanged(HkDistrict district) {
    final subAreas = hkSubAreasForDistrict(district.nameZh);
    setState(() {
      selectedDistrict = district;
      selectedSubArea = subAreas.first;
    });
    _scheduleGeocode();
  }

  void _onSubAreaChanged(HkSubArea subArea) {
    setState(() => selectedSubArea = subArea);
    _scheduleGeocode();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.s.shopRegister)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: storeNameController, label: context.s.merchantName),
          AppTextField(
            controller: emailController,
            label: context.s.emailLabel,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 148,
                child: CountryCodeDropdown(
                  value: countryCode,
                  onChanged: (value) => setState(() => countryCode = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: AppTextField(
                      controller: phoneController, label: context.s.merchantPhoneNumber)),
            ],
          ),
          AppTextField(
              controller: verificationController,
              label: context.s.emailVerificationCode),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _codeCooldown > 0 ? null : _sendEmailCode,
              child: Text(
                  _codeCooldown > 0 ? context.s.smsResendIn(_codeCooldown) : context.s.getVerificationCode),
            ),
          ),
          AppTextField(
            controller: passwordController,
            label: context.s.password,
            obscureText: true,
          ),
          const Divider(height: 28),
          HkDistrictPicker(
            majorRegion: majorRegion,
            districtName: selectedDistrict.nameZh,
            subAreaName: selectedSubArea.nameZh,
            detailController: addressDetailController,
            onMajorRegionChanged: _onMajorRegionChanged,
            onDistrictChanged: _onDistrictChanged,
            onSubAreaChanged: _onSubAreaChanged,
            onDetailChanged: (_) => _scheduleGeocode(),
          ),
          const SizedBox(height: 12),
          CarWashMapView(
            key: shopMapKey,
            height: 180,
            borderRadius: 16,
            cameraTarget: mapLocation,
            zoom: geocodedLocation == null ? 14 : 16,
            myLocationEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('shop-location'),
                position: mapLocation,
                infoWindow: InfoWindow(
                  title: storeNameController.text.trim().isEmpty
                      ? selectedSubArea.nameZh
                      : storeNameController.text.trim(),
                  snippet: geocodedAddress ?? fullAddress,
                ),
              ),
            },
          ),
          if (geocoding) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 8),
          Text(
            context.s.addressPreviewLine(
              locationLabel,
              addressDetailController.text.trim(),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (geocodingMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              geocodingMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: geocodedLocation == null
                        ? Theme.of(context).colorScheme.error
                        : Colors.green.shade700,
                  ),
            ),
          ],
          Text(
            context.s.coordinatesLine(
              mapLocation.latitude,
              mapLocation.longitude,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(context.s.merchantLicensePermit, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LicenseUploadSection(
            files: licenseFiles,
            onChanged: (files) => setState(() {
              licenseFiles
                ..clear()
                ..addAll(files);
              error = null;
            }),
          ),
          const SizedBox(height: 8),
          Text(context.s.serviceTypes, style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final type in sortedWashServiceTypes(serviceTypes))
            CheckboxListTile(
              value: serviceTypes.contains(type),
              onChanged: (value) => setState(() {
                _toggleService(type, value ?? false);
              }),
              title: Text(type.label),
              subtitle: washServiceTypeSubtitle(type),
              secondary: Icon(type.icon),
            ),
          if (serviceTypes.contains(WashServiceType.selfService))
            const SelfServiceEcoBanner(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          Text(
            apiConnectionHint(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: submitting
                ? null
                : () async {
                    try {
                      _validateRequired([
                        storeNameController.text,
                        emailController.text,
                        phoneController.text,
                        verificationController.text,
                        passwordController.text,
                      ]);
                      if (licenseFiles.isEmpty) {
                        throw StateError(context.s.errUploadLicense);
                      }
                      if (serviceTypes.isEmpty) {
                        throw StateError(context.s.errSelectOneService);
                      }
                      setState(() {
                        submitting = true;
                        error = null;
                      });
                      await store.registerShop(
                        countryCode: countryCode,
                        phone: phoneController.text,
                        email: emailController.text,
                        verificationCode: verificationController.text,
                        password: passwordController.text,
                        storeName: storeNameController.text,
                        address: fullAddress,
                        latitude: mapLocation.latitude,
                        longitude: mapLocation.longitude,
                        licenseFiles: licenseFiles,
                        serviceTypes: serviceTypes,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.s.shopRegSubmittedAdmin)),
                      );
                    } on Object catch (exception) {
                      if (!mounted) {
                        return;
                      }
                      setState(() => error = exception
                          .toString()
                          .replaceFirst('Bad state: ', '')
                          .replaceFirst('ApiException: ', ''));
                    } finally {
                      if (mounted) {
                        setState(() => submitting = false);
                      }
                    }
                  },
            child: Text(submitting ? context.s.submittingLabel : context.s.registerShopOnMap),
          ),
        ],
      ),
    );
  }

  void _toggleService(WashServiceType type, bool selected) {
    if (selected) {
      serviceTypes.add(type);
    } else {
      serviceTypes.remove(type);
    }
  }

  Future<void> _sendEmailCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => error = context.s.fillEmailFirst);
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => error = context.s.invalidEmailFormat);
      return;
    }
    try {
      await ApiClient.sendEmailCode(
        email: email,
        purpose: 'register_shop',
      );
      setState(() {
        error = null;
        _codeCooldown = 60;
      });
      _codeTimer?.cancel();
      _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_codeCooldown <= 1) {
          timer.cancel();
          if (mounted) setState(() => _codeCooldown = 0);
        } else if (mounted) {
          setState(() => _codeCooldown -= 1);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.emailCodeSent)),
        );
      }
    } on Object catch (e) {
      setState(() => error = e.toString());
    }
  }
}

/// 切换用户端底部导航 Tab（0 洗车 / 1 套餐 / 2 订单 / 3 我的）
void switchUserShellTab(BuildContext context, int tabIndex) {
  context.findAncestorStateOfType<_UserShellState>()?.switchToTab(tabIndex);
}

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int index = 0;

  void switchToTab(int tabIndex) {
    if (tabIndex < 0 || tabIndex > 3) {
      return;
    }
    setState(() => index = tabIndex);
  }

  Widget _buildPage(int tabIndex) {
    return switch (tabIndex) {
      0 => const UserHomePage(key: PageStorageKey('user_home')),
      1 => const BundlePurchasePage(
          key: PageStorageKey('user_packages'),
          embedded: true,
        ),
      2 => const UserOrdersPage(key: PageStorageKey('user_orders')),
      3 => const UserProfilePage(key: PageStorageKey('user_profile')),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: kUserShellFabClearance),
          child: LazyIndexedShell(
            index: index,
            pageCount: 4,
            pageBuilder: _buildPage,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        heroTag: 'user-scan-fab',
        onPressed: () async {
          final qr = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const QrScanPage()),
          );
          if (qr == null || !context.mounted) return;
          final appStore = AppScope.of(context);
          final device = appStore.deviceByQr(qr);
          final store = device == null
              ? null
              : appStore.storeForDevice(device.id);
          if (store == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.s.unknownQr)),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScanPayPage(
                initialStore: store,
                initialQrCode: qr,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 6,
        child: const Icon(Icons.qr_code_scanner, size: 36, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: UserDockedBottomNav(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
          if (value == 1) {
            unawaited(AppScope.of(context).refreshBundlePlans());
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.local_car_wash_outlined),
            selectedIcon: const Icon(Icons.local_car_wash),
            label: context.s.tabCarWash,
          ),
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number_outlined),
            selectedIcon: const Icon(Icons.confirmation_number),
            label: context.s.tabPackages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: context.s.tabOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.s.tabProfile,
          ),
        ],
      ),
    );
  }
}

class UserReservationsPage extends StatefulWidget {
  const UserReservationsPage({super.key});

  @override
  State<UserReservationsPage> createState() => _UserReservationsPageState();
}

class _UserReservationsPageState extends State<UserReservationsPage> {
  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final reservations = appStore.reservations
            .where((reservation) => reservation.userAccountId == account.id)
            .toList();
        final stores = appStore.approvedStores();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionTitle(
              title: context.s.myReservations,
              subtitle: context.s.myReservationsSubtitle,
            ),
            const SizedBox(height: 12),
            if (stores.isEmpty)
              EmptyState(
                icon: Icons.storefront_outlined,
                title: context.s.noStoresToReserve,
                description: context.s.noStoresToReserveDesc,
              )
            else
              ReservationFormCard(
                stores: stores,
                userLocation: fallbackUserLocation,
              ),
            const SizedBox(height: 20),
            Text(context.s.reservationRecords, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (reservations.isEmpty)
              EmptyState(
                icon: Icons.calendar_month_outlined,
                title: context.s.noReservationsYet,
                description: context.s.noReservationsYetDesc,
              )
            else
              for (final reservation in reservations) ...[
                ReservationCard(reservation: reservation, showActions: true),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}

class ReservationFormCard extends StatefulWidget {
  const ReservationFormCard({
    required this.stores,
    required this.userLocation,
    super.key,
  });

  final List<CarWashStore> stores;
  final LatLng userLocation;

  @override
  State<ReservationFormCard> createState() => _ReservationFormCardState();
}

class _ReservationFormCardState extends State<ReservationFormCard> {
  late String selectedStoreId = widget.stores.first.id;
  late WashServiceType selectedType = _defaultServiceType();
  late DateTime selectedDate = _todayDateOnly();
  late String selectedTime = _currentTimeLabel();
  final phoneController = TextEditingController();
  final noteController = TextEditingController();
  bool phoneInitialized = false;
  String? error;

  CarWashStore get selectedStore =>
      widget.stores.firstWhere((store) => store.id == selectedStoreId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (phoneInitialized) {
      return;
    }
    final appStore = AppScope.of(context);
    phoneController.text =
        appStore.lastReservationPhone ?? appStore.currentAccount?.phone ?? '';
    phoneInitialized = true;
  }

  @override
  void dispose() {
    phoneController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final distanceKm =
        distanceBetweenKm(widget.userLocation, selectedStore.position);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.s.newReservation, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedStoreId,
              decoration: InputDecoration(labelText: context.s.selectStore,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final store in widget.stores)
                  DropdownMenuItem(
                    value: store.id,
                    child: Text(
                      store.localizedName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  selectedStoreId = value;
                  selectedType = _defaultServiceType();
                  error = null;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              context.s.reservationDistanceEta(distanceKm, estimateEtaMinutes(distanceKm)),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedStore.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                final dateField = DropdownButtonFormField<DateTime>(
                  isExpanded: true,
                  initialValue: selectedDate,
                  decoration: InputDecoration(labelText: context.s.reservationDate,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final date in _dateOptions())
                      DropdownMenuItem(
                        value: date,
                        child: Text(
                          formatDateOnly(date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedDate = value);
                    }
                  },
                );
                final timeField = DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedTime,
                  decoration: InputDecoration(labelText: context.s.reservationTime,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final time in _timeOptions())
                      DropdownMenuItem(value: time, child: Text(time)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedTime = value);
                    }
                  },
                );
                if (narrow) {
                  return Column(
                    children: [
                      dateField,
                      const SizedBox(height: 12),
                      timeField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dateField),
                    const SizedBox(width: 12),
                    Expanded(child: timeField),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            AppTextField(controller: phoneController, label: context.s.contactPhone),
            const SizedBox(height: 8),
            Text(context.s.reservationType, style: const TextStyle(fontWeight: FontWeight.w700)),
            for (final type in sortedWashServiceTypes(selectedStore.serviceTypes))
              RadioListTile<WashServiceType>(
                value: type,
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
                dense: true,
                title: Text(type.label),
                subtitle: washServiceTypeSubtitle(
                  type,
                  manualHint: context.s.manualServiceDetailHint,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            if (selectedType == WashServiceType.selfService)
              const SelfServiceEcoBanner(),
            TextField(
              controller: noteController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.s.reservationNotePlaceholder,
                border: const OutlineInputBorder(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                try {
                  final reservation = await appStore.createReservation(
                    storeId: selectedStoreId,
                    serviceType: selectedType,
                    userLocation: widget.userLocation,
                    arrivalTime: _arrivalDateTime(),
                    contactPhone: phoneController.text,
                    note: noteController.text,
                  );
                  if (!context.mounted) return;
                  noteController.clear();
                  setState(() => error = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.s.reservationSubmittedEta(reservation.etaMinutes),
                      ),
                    ),
                  );
                } on StateError catch (exception) {
                  setState(() => error = exception.message);
                } on Object catch (exception) {
                  setState(() => error = exception.toString());
                }
              },
              icon: const Icon(Icons.send),
              label: Text(context.s.submitReservation),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _arrivalDateTime() {
    final parts = selectedTime.split(':');
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  WashServiceType _defaultServiceType() {
    return sortedWashServiceTypes(selectedStore.serviceTypes).first;
  }
}

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final GlobalKey<CarWashMapViewState> mapKey = GlobalKey<CarWashMapViewState>();
  LatLng userLocation = fallbackUserLocation;
  CarWashStore? selectedStore;
  bool locating = true;
  bool mapReady = false;
  String locationMessage = AppStrings.current.locationLoadingDots;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => mapReady = true);
      _loadLocation();
    });
  }

  List<CarWashStore> _sortedStores(AppStore appStore) {
    final visibleStores = appStore.approvedStores();
    return [...visibleStores]..sort(
        (a, b) => distanceBetweenKm(userLocation, a.position).compareTo(
          distanceBetweenKm(userLocation, b.position),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return CatalogBuilder(
      builder: (context, appStore) {
        final sortedStores = _sortedStores(appStore);
        final runningOrder = appStore.runningOrder;
        return RefreshIndicator(
          onRefresh: () => appStore.syncFromBackend(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SectionTitle(
                      title: context.s.carWashTitle,
                      subtitle: context.s.carWashSubtitle,
                    ),
                    SyncStatusBanner(
                      onRetry: appStore.syncFromBackend,
                    ),
                    if (runningOrder != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: AppColors.primarySurface,
                        child: ListTile(
                          leading: const AppIconBadge(
                            icon: Icons.local_car_wash,
                            size: 44,
                          ),
                          title: Text(
                            context.s.orderInProgress,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(context.s.clickForDetails),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final parent =
                                context.findAncestorStateOfType<_UserShellState>();
                            parent?.switchToTab(2);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: _UserHomeMapPanel(
                      mapKey: mapKey,
                      mapReady: mapReady,
                      userLocation: userLocation,
                      selectedStore: selectedStore,
                      locating: locating,
                      locationMessage: locationMessage,
                      stores: appStore.approvedStores(),
                      onStoreSelected: (washStore) {
                        setState(() => selectedStore = washStore);
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(locationMessage),
                    if (locating) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                    if (selectedStore != null) ...[
                      const SizedBox(height: 8),
                      NavigationPanel(
                        store: selectedStore!,
                        userLocation: userLocation,
                        distanceKm: distanceBetweenKm(
                          userLocation,
                          selectedStore!.position,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      context.s.nearbyStores,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
              if (sortedStores.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.store_outlined,
                      title: context.s.noStores,
                      description: context.s.noStoresDesc,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: sortedStores.length,
                    itemBuilder: (context, index) {
                      final washStore = sortedStores[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == sortedStores.length - 1 ? 0 : 12,
                        ),
                        child: StoreCard(
                          key: ValueKey(washStore.id),
                          store: washStore,
                          distanceKm: distanceBetweenKm(
                            userLocation,
                            washStore.position,
                          ),
                          onFocusMap: () => _focusStore(washStore),
                          onNavigate: () => _openGoogleNavigation(washStore),
                          onReserve: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateReservationPage(
                                store: washStore,
                                userLocation: userLocation,
                              ),
                            ),
                          ),
                          onScan: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ScanPayPage(initialStore: washStore),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!enabled) {
        setState(() {
          locating = false;
          locationMessage = context.s.locationDisabledHkFallback;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          locating = false;
          locationMessage = context.s.locationDeniedHkFallback;
        });
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        final cachedLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
        setState(() {
          userLocation = cachedLocation;
          locating = true;
          locationMessage = context.s.locationLoadingDots;
        });
        await mapKey.currentState?.moveCamera(cachedLocation);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = location;
        locating = false;
        locationMessage = context.s.locationSuccessSorted;
      });
      await mapKey.currentState?.moveCamera(location);
    } on Object {
      if (!mounted) return;
      setState(() {
        locating = false;
        locationMessage = context.s.locationFailedHkFallback;
      });
    }
  }

  Future<void> _focusStore(CarWashStore store) async {
    if (!mounted) return;
    setState(() => selectedStore = store);
    await mapKey.currentState?.moveCamera(store.position, zoom: 14);
  }

  Future<void> _openGoogleNavigation(CarWashStore store) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${userLocation.latitude},${userLocation.longitude}&destination=${store.latitude},${store.longitude}&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _UserHomeMapPanel extends StatefulWidget {
  const _UserHomeMapPanel({
    required this.mapKey,
    required this.mapReady,
    required this.userLocation,
    required this.selectedStore,
    required this.locating,
    required this.locationMessage,
    required this.stores,
    required this.onStoreSelected,
  });

  final GlobalKey<CarWashMapViewState> mapKey;
  final bool mapReady;
  final LatLng userLocation;
  final CarWashStore? selectedStore;
  final bool locating;
  final String locationMessage;
  final List<CarWashStore> stores;
  final ValueChanged<CarWashStore> onStoreSelected;

  @override
  State<_UserHomeMapPanel> createState() => _UserHomeMapPanelState();
}

class _UserHomeMapPanelState extends State<_UserHomeMapPanel> {
  static BitmapDescriptor? _userMarkerIcon;
  static BitmapDescriptor? _storeMarkerIcon;

  Set<Marker> _markers = const {};
  Set<Polyline> _polylines = const {};

  @override
  void initState() {
    super.initState();
    _ensureMarkerIcons();
    _rebuildOverlays();
  }

  @override
  void didUpdateWidget(covariant _UserHomeMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userLocation != widget.userLocation ||
        oldWidget.selectedStore?.id != widget.selectedStore?.id ||
        oldWidget.mapReady != widget.mapReady ||
        _storeIdsChanged(oldWidget.stores, widget.stores)) {
      _rebuildOverlays();
    }
  }

  bool _storeIdsChanged(List<CarWashStore> a, List<CarWashStore> b) {
    if (a.length != b.length) {
      return true;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return true;
      }
    }
    return false;
  }

  Future<void> _ensureMarkerIcons() async {
    _userMarkerIcon ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    _storeMarkerIcon ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
    if (mounted) {
      _rebuildOverlays();
    }
  }

  void _rebuildOverlays() {
    final userIcon = _userMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    final storeIcon = _storeMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: widget.userLocation,
        icon: userIcon,
        infoWindow: InfoWindow(title: AppStrings.current.myLocation),
      ),
      for (final washStore in widget.stores)
        Marker(
          markerId: MarkerId(washStore.id),
          position: washStore.position,
          icon: storeIcon,
          infoWindow: InfoWindow(
            title: washStore.localizedName(),
            snippet: washStore.serviceSummary,
          ),
          onTap: () => widget.onStoreSelected(washStore),
        ),
    };
    final polylines = <Polyline>{
      if (widget.selectedStore != null)
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: [widget.userLocation, widget.selectedStore!.position],
        ),
    };
    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.mapReady) {
      return SizedBox(
        height: 220,
        child: Card(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  widget.locationMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return CarWashMapView(
      key: widget.mapKey,
      height: 220,
      cameraTarget: widget.userLocation,
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: !widget.locating,
      onTap: (_) {},
    );
  }
}

class NavigationPanel extends StatelessWidget {
  const NavigationPanel({
    required this.store,
    required this.userLocation,
    required this.distanceKm,
    super.key,
  });

  final CarWashStore store;
  final LatLng userLocation;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.route),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.s.navigationPanelText(
                  store.localizedName(),
                  distanceKm,
                  estimateEtaMinutes(distanceKm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  const StoreCard({
    required this.store,
    required this.distanceKm,
    required this.onFocusMap,
    required this.onNavigate,
    required this.onReserve,
    required this.onScan,
    super.key,
  });

  final CarWashStore store;
  final double distanceKm;
  final VoidCallback onFocusMap;
  final VoidCallback onNavigate;
  final VoidCallback onReserve;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final idleCount = store.devices
        .where((device) => device.status == DeviceStatus.idle)
        .length;
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
                  child: Text(
                    store.localizedName(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text('${distanceKm.toStringAsFixed(1)} km'),
              ],
            ),
            const SizedBox(height: 6),
            Text(store.localizedAddress()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(icon: Icons.star, label: store.rating.toString()),
                InfoChip(icon: Icons.event_available, label: context.s.idleBaysCount(idleCount)),
                for (final type in store.serviceTypes)
                  InfoChip(label: type.label, icon: type.icon),
                for (final tag in store.localizedTags()) InfoChip(label: tag),
              ],
            ),
            if (store.serviceTypes.contains(WashServiceType.selfService)) ...[
              const SizedBox(height: 10),
              const SelfServiceEcoBanner(),
            ],
            const SizedBox(height: 12),
            DeviceStatusList(devices: store.devices),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onFocusMap,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(context.s.viewMap),
                ),
                OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined),
                  label: Text(context.s.googleNav),
                ),
                FilledButton.tonalIcon(
                  onPressed: onReserve,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(context.s.reserveStore),
                ),
                FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(context.s.scanCarWashTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({
    required this.store,
    required this.userLocation,
    super.key,
  });

  final CarWashStore store;
  final LatLng userLocation;

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  late WashServiceType selectedType = _defaultServiceType();
  late DateTime selectedDate = _todayDateOnly();
  late String selectedTime = _currentTimeLabel();
  final phoneController = TextEditingController();
  final noteController = TextEditingController();
  bool phoneInitialized = false;
  String? error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (phoneInitialized) {
      return;
    }
    final appStore = AppScope.of(context);
    phoneController.text =
        appStore.lastReservationPhone ?? appStore.currentAccount?.phone ?? '';
    phoneInitialized = true;
  }

  @override
  void dispose() {
    phoneController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final distanceKm =
        distanceBetweenKm(widget.userLocation, widget.store.position);
    return Scaffold(
      appBar: AppBar(title: Text(context.s.reserveStore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(
            title: widget.store.localizedName(),
            subtitle:
                context.s.reservationDistanceEtaPeriod(distanceKm, estimateEtaMinutes(distanceKm)),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final dateField = DropdownButtonFormField<DateTime>(
                isExpanded: true,
                initialValue: selectedDate,
                decoration: InputDecoration(labelText: context.s.reservationDate,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final date in _dateOptions())
                    DropdownMenuItem(
                      value: date,
                      child: Text(
                        formatDateOnly(date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedDate = value);
                  }
                },
              );
              final timeField = DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedTime,
                decoration: InputDecoration(labelText: context.s.reservationTime,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final time in _timeOptions())
                    DropdownMenuItem(value: time, child: Text(time)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedTime = value);
                  }
                },
              );
              if (narrow) {
                return Column(
                  children: [
                    dateField,
                    const SizedBox(height: 12),
                    timeField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dateField),
                  const SizedBox(width: 12),
                  Expanded(child: timeField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          AppTextField(controller: phoneController, label: context.s.contactPhone),
          const SizedBox(height: 8),
          Text(context.s.selectReservationTypeLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final type in sortedWashServiceTypes(widget.store.serviceTypes))
            RadioListTile<WashServiceType>(
              value: type,
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value!),
              dense: true,
              title: Text(type.label),
              subtitle: washServiceTypeSubtitle(
                type,
                manualHint: context.s.manualServiceDetailHint,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          if (selectedType == WashServiceType.selfService)
            const SelfServiceEcoBanner(),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 4,
            decoration: InputDecoration(labelText: context.s.reservationNotePlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              try {
                final reservation = await appStore.createReservation(
                  storeId: widget.store.id,
                  serviceType: selectedType,
                  userLocation: widget.userLocation,
                  arrivalTime: _arrivalDateTime(),
                  contactPhone: phoneController.text,
                  note: noteController.text,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(context.s.reservationSubmittedEta(reservation.etaMinutes))),
                );
              } on StateError catch (exception) {
                setState(() => error = exception.message);
              } on Object catch (exception) {
                setState(() => error = exception.toString());
              }
            },
            icon: const Icon(Icons.send),
            label: Text(context.s.submitReservation),
          ),
        ],
      ),
    );
  }

  DateTime _arrivalDateTime() {
    final parts = selectedTime.split(':');
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  WashServiceType _defaultServiceType() {
    final sorted = sortedWashServiceTypes(widget.store.serviceTypes);
    return sorted.first;
  }
}

class ScanPayPage extends StatefulWidget {
  const ScanPayPage({this.initialStore, this.initialQrCode, super.key});

  final CarWashStore? initialStore;
  final String? initialQrCode;

  @override
  State<ScanPayPage> createState() => _ScanPayPageState();
}

class _ScanPayPageState extends State<ScanPayPage> {
  late String qrCode;
  late String selectedPackageId;
  bool useFreeWashThisOrder = false;
  bool usePrepaidWashThisOrder = false;
  bool isProcessing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WashDevice? firstIdleDevice;
    for (final device in widget.initialStore?.devices ?? <WashDevice>[]) {
      if (device.status == DeviceStatus.idle) {
        firstIdleDevice = device;
        break;
      }
    }
    qrCode = widget.initialQrCode ??
        firstIdleDevice?.qrCode ??
        'CARWASH-1001';
    selectedPackageId = widget.initialStore?.packages.first.id ?? 'basic';
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final selectedDevice = appStore.deviceByQr(qrCode);
    final selectedStore = selectedDevice == null
        ? widget.initialStore
        : appStore.storeForDevice(selectedDevice.id);
    final anchorStore = selectedStore ?? widget.initialStore;
    final availableStores = appStore.approvedStoresForScanContext(
      anchorStore: anchorStore,
    );
    final packages = selectedStore?.packages ??
        (availableStores.isNotEmpty
            ? availableStores.first.packages
            : appStore.approvedStores().first.packages);
    if (!packages.any((washPackage) => washPackage.id == selectedPackageId)) {
      selectedPackageId = packages.first.id;
    }
    final account = appStore.currentAccount;
    final freeWashCredits =
        account?.role == AccountRole.user ? account!.freeWashCredits : 0;
    final prepaidCredits =
        account?.role == AccountRole.user ? account!.prepaidWashCredits : 0;
    final selectedPackage =
        packages.firstWhere((washPackage) => washPackage.id == selectedPackageId);
    final canUseFreeWash = freeWashCredits > 0;
    final canUsePrepaid = prepaidCredits > 0;
    final usingCredit = useFreeWashThisOrder && canUseFreeWash ||
        usePrepaidWashThisOrder && canUsePrepaid;
    final actualAmount = usingCredit ? 0.0 : selectedPackage.price;

    return Scaffold(
      appBar: AppBar(title: Text(context.s.scanPayTitle)),
      body: AnimatedBuilder(
        animation: appStore,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(
                title: context.s.scanCarWashTitle,
                subtitle: context.s.scanCarWashSubtitle,
              ),
              const SizedBox(height: 8),
              const SelfServiceEcoBanner(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final code = await Navigator.of(context).push<String>(
                          MaterialPageRoute(builder: (_) => const QrScanPage()),
                        );
                        if (code == null) return;
                        setState(() {
                          qrCode = code;
                          error = null;
                        });
                      },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(context.s.rescan),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: qrCode,
                decoration: InputDecoration(labelText: context.s.currentDeviceLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final store in availableStores)
                    for (final device in store.devices)
                      DropdownMenuItem(
                        value: device.qrCode,
                        child: Text(
                          '${device.qrCode} - ${store.localizedName()} ${device.localizedBayName()}',
                        ),
                      ),
                ],
                onChanged: isProcessing
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        final device = appStore.deviceByQr(value);
                        final store = device == null
                            ? null
                            : appStore.storeForDevice(device.id);
                        setState(() {
                          qrCode = value;
                          selectedPackageId =
                              store?.packages.first.id ?? selectedPackageId;
                          error = null;
                        });
                      },
              ),
              const SizedBox(height: 16),
              if (selectedStore != null && selectedDevice != null)
                ScanDeviceSummary(store: selectedStore, device: selectedDevice),
              if (account?.role == AccountRole.user) ...[
                const SizedBox(height: 12),
                Card(
                  color: canUseFreeWash
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  child: SwitchListTile(
                    title: Text(
                      canUseFreeWash
                          ? context.s.useFreeWashRemaining(freeWashCredits)
                          : context.s.useFreeWashOff,
                      style: TextStyle(
                        color: canUseFreeWash
                            ? null
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    subtitle: Text(
                      canUseFreeWash
                          ? context.s.useFreeWashSubtitlePay
                          : context.s.useFreeWashSubtitleOff,
                      style: TextStyle(
                        color: canUseFreeWash
                            ? null
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    value: canUseFreeWash && useFreeWashThisOrder,
                    onChanged: !isProcessing && canUseFreeWash
                        ? (value) => setState(() {
                              useFreeWashThisOrder = value;
                              if (value) usePrepaidWashThisOrder = false;
                            })
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: canUsePrepaid
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  child: SwitchListTile(
                    title: Text(
                      canUsePrepaid
                          ? context.s.usePrepaidRemaining(prepaidCredits)
                          : context.s.usePrepaidOff,
                    ),
                    subtitle: Text(
                      canUsePrepaid
                          ? context.s.usePrepaidSubtitleOn
                          : context.s.usePrepaidSubtitleOff,
                    ),
                    value: canUsePrepaid && usePrepaidWashThisOrder,
                    onChanged: !isProcessing && canUsePrepaid
                        ? (value) => setState(() {
                              usePrepaidWashThisOrder = value;
                              if (value) useFreeWashThisOrder = false;
                            })
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(context.s.selectPackageLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final washPackage in packages)
                PackageOptionCard(
                  package: washPackage,
                  selected: washPackage.id == selectedPackageId,
                  enabled: !isProcessing,
                  displayPrice: washPackage.id == selectedPackageId
                      ? actualAmount
                      : washPackage.price,
                  onTap: () =>
                      setState(() => selectedPackageId = washPackage.id),
                ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(context.s.actualPaymentLabel),
                  trailing: Text(
                    '¥${actualAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: useFreeWashThisOrder && canUseFreeWash
                      ? Text(
                          context.s.originalPriceFreeUsed(selectedPackage.price),
                        )
                      : usePrepaidWashThisOrder && canUsePrepaid
                          ? Text(
                              context.s.originalPricePrepaidUsed(selectedPackage.price),
                            )
                          : null,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed:
                    isProcessing ? null : () => _goToPayment(context, appStore),
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(
                  isProcessing
                      ? context.s.processingLabel
                      : actualAmount <= 0
                          ? context.s.confirmStartWash
                          : context.s.goToPayment(actualAmount),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _goToPayment(BuildContext context, AppStore appStore) async {
    if (isProcessing) {
      return;
    }
    if (qrCode.trim().isEmpty) {
      setState(() => error = context.s.selectDeviceQr);
      return;
    }
    if (selectedPackageId.trim().isEmpty) {
      setState(() => error = context.s.selectPackageRequired);
      return;
    }

    setState(() {
      isProcessing = true;
      error = null;
    });
    try {
      final order = await appStore.createPendingOrder(
        deviceQrCode: qrCode,
        packageId: selectedPackageId,
        useFreeWash: useFreeWashThisOrder,
        usePrepaidWash: usePrepaidWashThisOrder,
      );
      if (!context.mounted) {
        return;
      }

      if (order.amount <= 0) {
        if (order.status == OrderStatus.created) {
          await appStore.markOrderPaid(
            order.id,
            transactionId: 'FREE-${order.id}',
            paymentMethod: context.s.freeWashLabel,
          );
        }
        final latestOrder = appStore.orders.firstWhere(
          (candidate) => candidate.id == order.id,
        );
        await appStore.startOrder(latestOrder);
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.orderStartedFree(order.id))),
        );
        return;
      }

      final selectedDevice = appStore.deviceByQr(qrCode);
      final selectedStore = selectedDevice == null
          ? widget.initialStore
          : appStore.storeForDevice(selectedDevice.id);
      final packages =
          selectedStore?.packages ?? appStore.approvedStores().first.packages;
      final selectedPackage = packages.firstWhere(
        (washPackage) => washPackage.id == selectedPackageId,
      );
      final storeName = selectedStore?.name ?? context.s.defaultCarWashStore;
      final packageName = selectedPackage.localizedName();

      final paid = await launchWashOrderPayment(
        context: context,
        appStore: appStore,
        order: order,
        storeName: storeName,
        packageName: packageName,
      );
      if (paid == true && context.mounted) {
        Navigator.of(context).pop();
      }
    } on StateError catch (exception) {
      setState(() => error = exception.message);
    } on ApiException catch (exception) {
      setState(() => error = exception.message);
    } on ApiConnectionException catch (exception) {
      setState(() => error = exception.message);
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final account = appStore.currentAccount;
        final userOrders = appStore.orders
            .where(
                (order) => account == null || order.userAccountId == account.id)
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionTitle(
              title: context.s.myOrdersTitle,
              subtitle: context.s.myOrdersSubtitleTrack,
            ),
            const SizedBox(height: 12),
            if (userOrders.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: context.s.noOrdersYet,
                description: context.s.scanOnHomeHint,
              )
            else
              for (final order in userOrders) ...[
                OrderCard(order: order),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class ShopShell extends StatefulWidget {
  const ShopShell({super.key});

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int index = 0;

  Widget _buildPage(int tabIndex) {
    return switch (tabIndex) {
      0 => const ShopStoresPage(),
      1 => const ShopReservationsPage(),
      2 => const ShopPricingPage(),
      3 => const ShopProfilePage(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LazyIndexedShell(
          index: index,
          pageCount: 4,
          pageBuilder: _buildPage,
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: context.s.tabStores,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: context.s.tabReservations,
          ),
          NavigationDestination(
            icon: const Icon(Icons.price_change_outlined),
            selectedIcon: const Icon(Icons.price_change),
            label: context.s.tabPricing,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.s.tabMine,
          ),
        ],
      ),
    );
  }
}

class ShopStoresPage extends StatelessWidget {
  const ShopStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogBuilder(
      builder: (context, appStore) {
        final stores = appStore.storesForCurrentShop();
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  TopBar(
                    title: context.s.shopMerchantTitle,
                    subtitle: context.s.shopMerchantSubtitleNamed(
                      appStore.currentAccount?.displayName ?? '',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddShopStorePage()),
                    ),
                    icon: const Icon(Icons.add_business),
                    label: Text(context.s.addNewShopBtn),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.builder(
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == stores.length - 1 ? 0 : 12),
                    child: ShopStoreCard(store: store, showAddBay: true),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class ShopReservationsPage extends StatefulWidget {
  const ShopReservationsPage({super.key});

  @override
  State<ShopReservationsPage> createState() => _ShopReservationsPageState();
}

class _ShopReservationsPageState extends State<ShopReservationsPage> {
  String selectedStoreId = 'all';

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final stores = appStore.storesForCurrentShop();
        final reservations =
            appStore.reservationsForCurrentShop().where((item) {
          return selectedStoreId == 'all' || item.storeId == selectedStoreId;
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TopBar(title: context.s.reservationFormShopTitle, subtitle: context.s.reservationFormShopSubtitle),
            StoreFilterDropdown(
              stores: stores,
              value: selectedStoreId,
              onChanged: (value) => setState(() => selectedStoreId = value),
            ),
            const SizedBox(height: 12),
            if (reservations.isEmpty)
              EmptyState(
                icon: Icons.calendar_month_outlined,
                title: context.s.noReservationsYet,
                description: context.s.shopReservationsEmptyDesc,
              )
            else
              for (final reservation in reservations) ...[
                ReservationCard(reservation: reservation, showActions: true),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class ShopOrdersPage extends StatefulWidget {
  const ShopOrdersPage({super.key});

  @override
  State<ShopOrdersPage> createState() => _ShopOrdersPageState();
}

class _ShopOrdersPageState extends State<ShopOrdersPage> {
  String selectedStoreId = 'all';

  @override
  Widget build(BuildContext context) {
    return CatalogBuilder(
      builder: (context, appStore) {
        final stores = appStore.storesForCurrentShop();
        final orders = appStore.ordersForCurrentShop().where((item) {
          return selectedStoreId == 'all' || item.storeId == selectedStoreId;
        }).toList();
        final completed = orders
            .where((order) => order.status == OrderStatus.completed)
            .length;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  TopBar(
                    title: context.s.shopOrdersTitle,
                    subtitle: context.s.shopOrdersSubtitle,
                  ),
                  StoreFilterDropdown(
                    stores: stores,
                    value: selectedStoreId,
                    onChanged: (value) => setState(() => selectedStoreId = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: context.s.collected,
                          value:
                              '¥${appStore.receivedRevenueForCurrentShop(storeId: selectedStoreId == 'all' ? null : selectedStoreId).toStringAsFixed(0)}',
                          icon: Icons.payments,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MetricCard(
                          label: context.s.pendingPay,
                          value: context.s.orderCountUnit(
                            appStore.pendingPaymentCountForCurrentShop(
                              storeId: selectedStoreId == 'all' ? null : selectedStoreId,
                            ),
                          ),
                          icon: Icons.hourglass_empty,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MetricCard(
                    label: context.s.completedOrdersLabel,
                    value: '$completed / ${orders.length}',
                    icon: Icons.done_all,
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            if (orders.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: context.s.noOrdersShopTitle,
                    description: context.s.shopOrdersEmptyDesc,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == orders.length - 1 ? 0 : 8),
                      child: OrderCard(order: orders[index]),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  int pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    try {
      final pending = await ApiClient.fetchAdminPending();
      if (!mounted) return;
      setState(() {
        pendingCount = (pending['pending_account_count'] as int? ?? 0) +
            (pending['pending_store_count'] as int? ?? 0);
      });
    } on Object {
      // keep previous count
    }
  }

  Widget _buildPage(int tabIndex) {
    return switch (tabIndex) {
      0 => AdminApprovalPage(onQueueChanged: _refreshPendingCount),
      1 => const AdminOverviewPage(),
      2 => const AdminStoresPage(),
      3 => const AdminReservationsPage(),
      4 => const AdminOrdersPage(),
      5 => const AdminPricingPage(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LazyIndexedShell(
          index: index,
          pageCount: 6,
          pageBuilder: _buildPage,
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
          if (value == 0) {
            _refreshPendingCount();
          }
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.fact_check_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.fact_check),
            ),
            label: context.s.tabApproval,
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: context.s.tabOverview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.store_outlined),
            selectedIcon: const Icon(Icons.store),
            label: context.s.tabStores,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: context.s.tabReservations,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: context.s.tabOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.price_change_outlined),
            selectedIcon: const Icon(Icons.price_change),
            label: context.s.tabPricing,
          ),
        ],
      ),
    );
  }
}

Future<void> _editStorePackagePrice(
  BuildContext context,
  AppStore appStore,
  CarWashStore store,
  ServicePackage washPackage,
) async {
  final priceController =
      TextEditingController(text: washPackage.price.toStringAsFixed(0));
  final minutesController =
      TextEditingController(text: '${washPackage.minutes}');
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.s.modifyPackageName(washPackage.localizedName())),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.s.priceYuanLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: minutesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.s.durationMinLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.s.cancelBtn),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.s.saveBtn),
        ),
      ],
    ),
  );
  if (saved != true) {
    priceController.dispose();
    minutesController.dispose();
    return;
  }
  try {
    final price = double.tryParse(priceController.text.trim());
    final minutes = int.tryParse(minutesController.text.trim());
    if (price == null || price < 0) {
      throw StateError(context.s.priceFormatInvalid);
    }
    if (minutes == null || minutes <= 0) {
      throw StateError(context.s.durationFormatInvalid);
    }
    await appStore.updateStorePackage(
      storeId: store.id,
      packageId: washPackage.id,
      price: price,
      minutes: minutes,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.packagePriceUpdated)),
      );
    }
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.saveFailedDetail(e))),
      );
    }
  } finally {
    priceController.dispose();
    minutesController.dispose();
  }
}

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TopBar(title: context.s.adminPlatformTitle, subtitle: context.s.adminOverviewSubtitle),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                MetricCard(
                    label: context.s.defaultUserLabel,
                    value:
                        '${appStore.accounts.where((a) => a.role == AccountRole.user).length}',
                    icon: Icons.person),
                MetricCard(
                    label: context.s.roleShop,
                    value:
                        '${appStore.accounts.where((a) => a.role == AccountRole.shop).length}',
                    icon: Icons.store),
                MetricCard(
                    label: context.s.metricMapPoints,
                    value: '${appStore.stores.length}',
                    icon: Icons.location_on),
                MetricCard(
                    label: context.s.tabReservations,
                    value: '${appStore.reservations.length}',
                    icon: Icons.calendar_month),
                MetricCard(
                    label: context.s.tabOrders,
                    value: '${appStore.orders.length}',
                    icon: Icons.receipt_long),
                MetricCard(
                    label: context.s.metricFaultDevices,
                    value: '${appStore.alertDeviceCount}',
                    icon: Icons.warning_amber),
              ],
            ),
          ],
        );
      },
    );
  }
}

class AdminAccountsPage extends StatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  bool syncing = false;
  String? syncError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAccounts());
  }

  Future<void> _refreshAccounts() async {
    setState(() {
      syncing = true;
      syncError = null;
    });
    try {
      await AppScope.of(context).syncAccountsFromBackend();
    } on Object catch (error) {
      syncError = error.toString();
    } finally {
      if (mounted) {
        setState(() => syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _refreshAccounts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TopBar(title: context.s.accountManagementTitle, subtitle: context.s.accountManagementSubtitle),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      apiConnectionHint(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (syncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      onPressed: _refreshAccounts,
                      icon: const Icon(Icons.refresh),
                      tooltip: context.s.refreshFromBackend,
                    ),
                ],
              ),
              if (syncError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    syncError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Text(context.s.userAccountMgmt, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final account in appStore.accounts
                  .where((item) => item.role == AccountRole.user))
                AccountApprovalCard(account: account),
              const SizedBox(height: 16),
              Text(context.s.shopAccountMgmt, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final account in appStore.accounts)
                if (account.role == AccountRole.shop)
                  AccountApprovalCard(account: account),
            ],
          ),
        );
      },
    );
  }
}

class AccountApprovalCard extends StatelessWidget {
  const AccountApprovalCard({required this.account, super.key});

  final AppAccount account;

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(account.role.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${account.displayName} (${account.username})',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                StatusPill(
                  text: account.approvalStatus.label,
                  color: account.approvalStatus.color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.s.accountRolePhoneLine(account.role.label, account.phone)),
            if (account.role == AccountRole.shop)
              for (final store in appStore.stores.where(
                (store) => store.ownerAccountId == account.id,
              ))
                Text(context.s.storeInfoLine(store.localizedName(), store.localizedAddress())),
            if (account.role == AccountRole.shop &&
                account.licenseFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_open),
                title: Text(context.s.viewLicenseCount(account.licenseFiles.length)),
                subtitle: Text(account.licenseFiles.join('，')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LicenseMaterialsPage(
                        title: context.s.licensePageTitle(account.displayName),
                        files: account.licenseFiles,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (account.adminReply.isNotEmpty)
              Text(context.s.adminReplyLine(account.adminReply)),
            if (account.role != AccountRole.admin) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => appStore.updateAccountApproval(
                      account,
                      ApprovalStatus.approved,
                      adminReply: context.s.approvedDefaultReply,
                    ),
                    child: Text(context.s.approve),
                  ),
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(context, appStore),
                    child: Text(context.s.rejectAndReply),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    AppStore appStore,
  ) async {
    final replyController = TextEditingController(text: account.adminReply);
    final reply = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.s.reviewReply),
          content: TextField(
            controller: replyController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(labelText: context.s.rejectReplyPlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.s.cancelBtn),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(replyController.text),
              child: Text(context.s.rejectAndSend),
            ),
          ],
        );
      },
    );
    replyController.dispose();
    if (reply == null) {
      return;
    }
    appStore.updateAccountApproval(
      account,
      ApprovalStatus.rejected,
      adminReply: reply.trim().isEmpty ? context.s.defaultRejectMessage : reply,
    );
  }
}

class AdminStoresPage extends StatelessWidget {
  const AdminStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogBuilder(
      builder: (context, appStore) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TopBar(
                  title: context.s.storesAndBays,
                  subtitle: context.s.storesAndBaysSubtitle,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.builder(
                itemCount: appStore.stores.length,
                itemBuilder: (context, index) {
                  final store = appStore.stores[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == appStore.stores.length - 1 ? 0 : 12,
                    ),
                    child: ShopStoreCard(store: store),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogBuilder(
      builder: (context, appStore) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TopBar(
                  title: context.s.allReservationsAdmin,
                  subtitle: context.s.reservationFormShopSubtitle,
                ),
              ),
            ),
            if (appStore.reservations.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: context.s.noReservationsYet,
                    description: context.s.adminReservationsEmptyDesc,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.builder(
                  itemCount: appStore.reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = appStore.reservations[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == appStore.reservations.length - 1 ? 0 : 8,
                      ),
                      child: ReservationCard(
                        reservation: reservation,
                        showActions: true,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogBuilder(
      builder: (context, appStore) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TopBar(
                  title: context.s.allOrdersAdmin,
                  subtitle: context.s.shopOrdersSubtitle,
                ),
              ),
            ),
            if (appStore.orders.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: context.s.noOrdersShopTitle,
                    description: context.s.adminOrdersEmptyDesc,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.builder(
                  itemCount: appStore.orders.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == appStore.orders.length - 1 ? 0 : 8,
                      ),
                      child: OrderCard(order: appStore.orders[index]),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class StoreFilterDropdown extends StatelessWidget {
  const StoreFilterDropdown({
    required this.stores,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<CarWashStore> stores;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: context.s.storeFilterLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: 'all', child: Text(context.s.allStoresFilter)),
        for (final store in stores)
          DropdownMenuItem(
            value: store.id,
            child: Text(
              store.localizedName(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final account = appStore.currentAccount!;
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TopBar(
              title: context.s.tabProfile,
              subtitle: '${account.displayName} · ${account.phone}',
            ),
            if (account.role == AccountRole.user) ...[
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
              const SizedBox(height: 12),
            ],
            FilledButton.tonalIcon(
              onPressed: appStore.logout,
              icon: const Icon(Icons.logout),
              label: Text(context.s.exitLogin),
            ),
          ],
        );
      },
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
      decoration: appGradientHeaderDecoration(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const LanguageSwitcher(),
          IconButton(
            onPressed: appStore.logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: context.s.exitLogin,
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    required this.reservation,
    this.showActions = false,
    super.key,
  });

  final Reservation reservation;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final store = appStore.storeById(reservation.storeId);
    final user = appStore.accountById(reservation.userAccountId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.localizedName(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  text: reservation.status.label,
                  color: reservation.status.color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.s.reservationUserLine(user.displayName, reservation.contactPhone),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(context.s.reservationTypeLine(reservation.serviceType.label)),
            Text(context.s.reservationArrivalLine(formatDateTime(reservation.arrivalTime))),
            Text(
              context.s.reservationEtaDistanceLine(reservation.etaMinutes, reservation.distanceKm),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (reservation.note.isNotEmpty)
              Text(
                context.s.reservationNoteLine(reservation.note),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            Text(context.s.reservationSubmitTimeLine(formatTime(reservation.createdAt))),
            if (showActions) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final status in _allowedReservationStatuses(
                    reservation,
                    appStore.currentAccount?.role,
                  ))
                    OutlinedButton(
                      onPressed: () {
                        appStore.updateReservationStatus(reservation, status);
                      },
                      child: Text(status.label),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<ReservationStatus> _allowedReservationStatuses(
  Reservation reservation,
  AccountRole? role,
) {
  if (role == AccountRole.user) {
    if (reservation.status == ReservationStatus.pending) {
      return [ReservationStatus.cancelled];
    }
    return [];
  }
  if (role == AccountRole.shop || role == AccountRole.admin) {
    switch (reservation.status) {
      case ReservationStatus.pending:
        return [ReservationStatus.arrived, ReservationStatus.cancelled];
      case ReservationStatus.arrived:
        return [ReservationStatus.completed, ReservationStatus.cancelled];
      default:
        return [];
    }
  }
  return [];
}

class ShopStoreCard extends StatelessWidget {
  const ShopStoreCard(
      {required this.store, this.showAddBay = false, super.key});

  final CarWashStore store;
  final bool showAddBay;

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.localizedName(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (store.approvalStatus == ApprovalStatus.pending)
                  StatusPill(text: context.s.storePendingReview, color: Colors.red)
                else if (store.approvalStatus == ApprovalStatus.rejected)
                  StatusPill(text: context.s.storeRejectedReview, color: Colors.grey),
              ],
            ),
            if (store.adminReply.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.s.platformOpinionLine(store.adminReply),
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const SizedBox(height: 6),
            Text(store.localizedAddress()),
            Text(context.s.serviceTypeLine(store.serviceSummary)),
            Text(
context.s.revenueSummary(
                appStore.receivedRevenueForCurrentShop(storeId: store.id),
                appStore.paidOrderCountForCurrentShop(storeId: store.id),
              ),
            ),
            const SizedBox(height: 8),
            Text(context.s.washPackagePrices, style: const TextStyle(fontWeight: FontWeight.w700)),
            for (final washPackage in store.packages)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(washPackage.localizedName()),
                subtitle: Text(context.s.minutesLabel(washPackage.minutes)),
                trailing: OutlinedButton(
                  onPressed: () => _editStorePackagePrice(
                    context,
                    appStore,
                    store,
                    washPackage,
                  ),
                  child: Text('¥${washPackage.price.toStringAsFixed(0)}'),
                ),
              ),
            if (showAddBay) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddWashBayPage(store: store),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(context.s.addWashBaySlot),
              ),
            ],
            const SizedBox(height: 10),
            for (final device in store.devices) ...[
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${device.localizedBayName()} · ${device.status.label}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          PopupMenuButton<DeviceStatus>(
                            onSelected: (status) {
                              appStore.markDeviceStatus(device.id, status);
                            },
                            itemBuilder: (menuContext) => [
                              PopupMenuItem(
                                value: DeviceStatus.idle,
                                child: Text(menuContext.s.setIdleOnline),
                              ),
                              PopupMenuItem(
                                value: DeviceStatus.offline,
                                child: Text(menuContext.s.setOffline),
                              ),
                              PopupMenuItem(
                                value: DeviceStatus.faulted,
                                child: Text(menuContext.s.setFault),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.s.deviceUsageLine(device.useCount, formatDurationSeconds(device.totalUseSeconds), device.faultCount),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddWashBayPage extends StatefulWidget {
  const AddWashBayPage({required this.store, super.key});

  final CarWashStore store;

  @override
  State<AddWashBayPage> createState() => _AddWashBayPageState();
}

class _AddWashBayPageState extends State<AddWashBayPage> {
  final bayNameController = TextEditingController();
  WashServiceType serviceType = WashServiceType.selfService;
  String? error;

  @override
  void dispose() {
    bayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.s.addWashBaySlot)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.store.localizedName(),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          AppTextField(
              controller: bayNameController, label: context.s.bayNameExample),
          DropdownButtonFormField<WashServiceType>(
            initialValue: serviceType,
            decoration: InputDecoration(labelText: context.s.bayTypeLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                  value: WashServiceType.selfService,
                  child: Text(context.s.selfServiceBayLabel)),
              DropdownMenuItem(
                  value: WashServiceType.manual,
                  child: Text(context.s.manualBayLabel)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => serviceType = value);
              }
            },
          ),
          if (serviceType == WashServiceType.selfService) ...[
            const SizedBox(height: 8),
            const SelfServiceEcoBanner(),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              try {
                _validateRequired([bayNameController.text]);
                appStore.addDeviceToStore(
                  storeId: widget.store.id,
                  bayName: bayNameController.text,
                  serviceType: serviceType,
                );
                Navigator.of(context).pop();
              } on Object catch (exception) {
                setState(() => error =
                    exception.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: Text(context.s.addBayButton),
          ),
        ],
      ),
    );
  }
}

class AddShopStorePage extends StatefulWidget {
  const AddShopStorePage({super.key});

  @override
  State<AddShopStorePage> createState() => _AddShopStorePageState();
}

class _AddShopStorePageState extends State<AddShopStorePage> {
  final storeNameController = TextEditingController();
  final addressController = TextEditingController();
  final latController = TextEditingController(text: '22.5420');
  final lngController = TextEditingController(text: '113.9360');
  final licenseFiles = <String>[];
  final serviceTypes = <WashServiceType>{WashServiceType.selfService};
  String? error;
  bool geocoding = false;
  String? geocodingMessage;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    addressController.addListener(_scheduleGeocode);
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    addressController.removeListener(_scheduleGeocode);
    storeNameController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  void _scheduleGeocode() {
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
        geocodingMessage = result.formattedAddress == null
            ? context.s.geocodeCoordsUpdated
            : context.s.geocodeLocated(result.formattedAddress!);
      });
    } on GeocodingException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => geocodingMessage = exception.message);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => geocodingMessage = context.s.geocodeFailedMsg(error));
    } finally {
      if (mounted) {
        setState(() => geocoding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final phone = appStore.currentAccount?.phone ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(context.s.addNewShopBtn)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.s.merchantPhoneLocked(phone)),
          const SizedBox(height: 12),
          AppTextField(controller: storeNameController, label: context.s.storeNameLabel),
          AppTextField(controller: addressController, label: context.s.storeAddressLabel),
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
                  child: AppTextField(controller: latController, label: context.s.latitude)),
              const SizedBox(width: 12),
              Expanded(
                  child: AppTextField(controller: lngController, label: context.s.longitude)),
            ],
          ),
          Text(context.s.licenseMaterials, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LicenseUploadSection(
            files: licenseFiles,
            onChanged: (files) => setState(() {
              licenseFiles
                ..clear()
                ..addAll(files);
              error = null;
            }),
          ),
          const SizedBox(height: 8),
          Text(context.s.serviceTypes, style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final type in sortedWashServiceTypes(serviceTypes))
            CheckboxListTile(
              value: serviceTypes.contains(type),
              onChanged: (value) => setState(() {
                _toggleAddStoreService(type, value ?? false);
              }),
              title: Text(type.label),
              subtitle: washServiceTypeSubtitle(type),
              secondary: Icon(type.icon),
            ),
          if (serviceTypes.contains(WashServiceType.selfService))
            const SelfServiceEcoBanner(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: () async {
              try {
                _validateRequired([
                  storeNameController.text,
                  addressController.text,
                  latController.text,
                  lngController.text,
                ]);
                if (licenseFiles.isEmpty) {
                  throw StateError(context.s.errUploadLicense);
                }
                if (serviceTypes.isEmpty) {
                  throw StateError(context.s.errSelectOneService);
                }
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null || lng == null) {
                  throw StateError(context.s.errInvalidLatLng);
                }
                await appStore.addStoreForCurrentShop(
                  storeName: storeNameController.text,
                  address: addressController.text,
                  latitude: lat,
                  longitude: lng,
                  licenseFiles: licenseFiles,
                  serviceTypes: serviceTypes,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.s.storeSubmitted)),
                );
              } on Object catch (exception) {
                setState(() => error =
                    exception.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: Text(context.s.submitNewStore),
          ),
        ],
      ),
    );
  }

  void _toggleAddStoreService(WashServiceType type, bool selected) {
    if (selected) {
      serviceTypes.add(type);
    } else {
      serviceTypes.remove(type);
    }
  }
}

class DeviceStatusList extends StatelessWidget {
  const DeviceStatusList({required this.devices, super.key});

  final List<WashDevice> devices;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final device in devices)
          Chip(
            avatar: Icon(
              statusIcon(device.status),
              size: 18,
              color: statusColor(device.status),
            ),
            label: Text('${device.localizedBayName()} ${device.status.label}'),
          ),
      ],
    );
  }
}

Future<bool> launchWashOrderPayment({
  required BuildContext context,
  required AppStore appStore,
  required WashOrder order,
  required String storeName,
  required String packageName,
}) {
  if (order.status != OrderStatus.created) {
    return Future.value(false);
  }
  if (order.amount <= 0) {
    return _completeZeroAmountOrder(context, appStore, order);
  }
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PaymentPage(
        checkout: PaymentCheckoutArgs(
          orderId: order.id,
          storeName: storeName,
          packageName: packageName,
          amount: order.amount,
          usedFreeWash: order.usedFreeWashCredit,
          payerDisplayName:
              appStore.currentAccount?.displayName ?? context.s.defaultUserLabel,
          payerPhone: appStore.currentAccount?.phone ?? '',
          onPaymentConfirmed: ({
            required transactionId,
            required method,
            providerReference,
          }) async {
            await appStore.markOrderPaid(
              order.id,
              transactionId: transactionId,
              paymentMethod: method.label,
              providerReference: providerReference,
            );
            final latestOrder = appStore.orders.firstWhere(
              (candidate) => candidate.id == order.id,
            );
            await appStore.startOrder(latestOrder);
          },
        ),
      ),
    ),
  ).then((paid) => paid ?? false);
}

Future<bool> _completeZeroAmountOrder(
  BuildContext context,
  AppStore appStore,
  WashOrder order,
) async {
  if (order.status == OrderStatus.created) {
    await appStore.markOrderPaid(
      order.id,
      transactionId: 'FREE-${order.id}',
      paymentMethod: context.s.freeWashLabel,
    );
  }
  final latestOrder = appStore.orders.firstWhere(
    (candidate) => candidate.id == order.id,
  );
  await appStore.startOrder(latestOrder);
  return true;
}

class ScanDeviceSummary extends StatelessWidget {
  const ScanDeviceSummary({
    required this.store,
    required this.device,
    super.key,
  });

  final CarWashStore store;
  final WashDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.localizedName(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('${device.localizedBayName()} · ${device.status.label}'),
            const SizedBox(height: 8),
            Text(context.s.storeAddressLine(store.localizedAddress())),
          ],
        ),
      ),
    );
  }
}

class PackageOptionCard extends StatelessWidget {
  const PackageOptionCard({
    required this.package,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.displayPrice,
    super.key,
  });

  final ServicePackage package;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final double? displayPrice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final price = displayPrice ?? package.price;
    return Card(
      color: selected ? colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colorScheme.primary : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${package.localizedName()}  ¥${price.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(context.s.packageMinutesDesc(package.minutes, package.localizedDescription())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final WashOrder order;

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    final store = appStore.storeById(order.storeId);
    final device = appStore.deviceById(order.deviceId);
    final washPackage = appStore.packageById(order.storeId, order.packageId);
    final isAdmin = appStore.currentAccount?.role == AccountRole.admin;
    final isUser = appStore.currentAccount?.role == AccountRole.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    washPackage.localizedName(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                StatusPill(text: order.status.label, color: order.status.color),
              ],
            ),
            const SizedBox(height: 8),
            Text(store.localizedName()),
            Text(
              order.usedFreeWashCredit
                  ? context.s.freeWashOnOrder(device.localizedBayName())
                  : '${device.localizedBayName()} · ¥${order.amount.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 6),
            Text(context.s.orderFlowLine(order.flowDescription)),
            if (order.paidAt != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.usedFreeWashCredit ? context.s.redeemedFreeWash : context.s.paidAmountLine(order.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                    if (order.paymentMethod != null)
                      Text(context.s.paymentMethodLine(order.paymentMethod!)),
                    if (order.paymentTransactionId != null)
                      Text(context.s.transactionIdLine(order.paymentTransactionId!)),
                    Text(context.s.paidAtLine(_formatPaidAt(order.paidAt!))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (order.status == OrderStatus.running)
              ListenableBuilder(
                listenable: appStore.orderTick,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: _progress(washPackage, order)),
                    const SizedBox(height: 8),
                    Text(context.s.remainingTimeLine(formatSeconds(order.remainingSeconds))),
                  ],
                ),
              )
            else ...[
              LinearProgressIndicator(value: _progress(washPackage, order)),
              const SizedBox(height: 8),
              Text(context.s.orderIdLine(order.id)),
            ],
            if (order.failureReason != null) ...[
              const SizedBox(height: 8),
              Text(
                order.failureReason!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (isAdmin && order.status == OrderStatus.created) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => appStore.simulatePaymentAndStart(order),
                icon: const Icon(Icons.payments_outlined),
                label: Text(context.s.simulatePayStart),
              ),
            ],
            if (isUser && order.status == OrderStatus.created) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  if (order.amount <= 0) {
                    await _completeZeroAmountOrder(context, appStore, order);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.s.orderStartedFree(order.id)),
                      ),
                    );
                    return;
                  }
                  final paid = await launchWashOrderPayment(
                    context: context,
                    appStore: appStore,
                    order: order,
                    storeName: store.localizedName(),
                    packageName: washPackage.localizedName(),
                  );
                  if (paid && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.s.paySuccess)),
                    );
                  }
                },
                icon: const Icon(Icons.payments_outlined),
                label: Text(
                  order.amount > 0
                      ? context.s.goToPayment(order.amount)
                      : context.s.confirmStartWash,
                ),
              ),
            ],
            if (isUser && order.status == OrderStatus.paid) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => appStore.startOrder(order),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(context.s.confirmStartWash),
              ),
            ],
            if (order.status == OrderStatus.running) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => appStore.finishOrder(order),
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(context.s.finishWash),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPaidAt(DateTime paidAt) {
    final local = paidAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  double _progress(ServicePackage washPackage, WashOrder order) {
    if (order.status == OrderStatus.completed) {
      return 1;
    }
    if (order.status != OrderStatus.running) {
      return 0;
    }
    final total = washPackage.minutes * 60;
    return ((total - order.remainingSeconds) / total).clamp(0, 1);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            const LanguageSwitcherLight(),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({required this.label, this.icon, super.key});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              AppIconBadge(icon: icon, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primarySurface,
                      AppColors.primary.withValues(alpha: 0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Icon(icon, size: 38, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

extension AccountRoleText on AccountRole {
  String get name {
    return switch (this) {
      AccountRole.user => 'user',
      AccountRole.shop => 'shop',
      AccountRole.admin => 'admin',
    };
  }

  String get label {
    final s = AppStrings.current;
    return switch (this) {
      AccountRole.user => s.roleUser,
      AccountRole.shop => s.roleShop,
      AccountRole.admin => s.roleAdmin,
    };
  }

  IconData get icon {
    return switch (this) {
      AccountRole.user => Icons.person_outline,
      AccountRole.shop => Icons.storefront,
      AccountRole.admin => Icons.admin_panel_settings_outlined,
    };
  }
}

extension ApprovalStatusText on ApprovalStatus {
  String get label {
    final s = AppStrings.current;
    return switch (this) {
      ApprovalStatus.pending => s.approvalPending,
      ApprovalStatus.approved => s.approvalApproved,
      ApprovalStatus.rejected => s.approvalRejected,
    };
  }

  Color get color {
    return switch (this) {
      ApprovalStatus.pending => Colors.orange,
      ApprovalStatus.approved => Colors.green,
      ApprovalStatus.rejected => Colors.red,
    };
  }
}

Widget? washServiceTypeSubtitle(
  WashServiceType type, {
  String? manualHint,
}) {
  final eco = type.ecoSubtitle;
  if (eco != null) {
    return Text(
      eco,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  if (manualHint == null) {
    return null;
  }
  return Text(
    manualHint,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}

class SelfServiceEcoBanner extends StatelessWidget {
  const SelfServiceEcoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.water_drop_outlined, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              WashServiceType.selfService.ecoSubtitle!,
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension WashServiceTypeText on WashServiceType {
  String get label {
    final s = AppStrings.current;
    return switch (this) {
      WashServiceType.selfService => s.selfService,
      WashServiceType.manual => s.manualService,
    };
  }

  String? get ecoSubtitle {
    final s = AppStrings.current;
    return switch (this) {
      WashServiceType.selfService => s.selfServiceEco,
      WashServiceType.manual => null,
    };
  }

  IconData get icon {
    return switch (this) {
      WashServiceType.selfService => Icons.water_drop_outlined,
      WashServiceType.manual => Icons.handyman_outlined,
    };
  }
}

List<WashServiceType> sortedWashServiceTypes(Set<WashServiceType> serviceTypes) {
  const order = [WashServiceType.selfService, WashServiceType.manual];
  return [
    for (final type in order)
      if (serviceTypes.contains(type)) type,
  ];
}

extension DeviceStatusText on DeviceStatus {
  String get label {
    final s = AppStrings.current;
    return switch (this) {
      DeviceStatus.idle => s.deviceIdle,
      DeviceStatus.busy => s.deviceBusy,
      DeviceStatus.offline => s.deviceOffline,
      DeviceStatus.faulted => s.deviceFaulted,
    };
  }
}

extension OrderStatusText on OrderStatus {
  String get label {
    final s = AppStrings.current;
    return switch (this) {
      OrderStatus.created => s.orderStatusCreated,
      OrderStatus.paid => s.orderStatusPaid,
      OrderStatus.starting => s.orderStatusStarting,
      OrderStatus.running => s.orderStatusRunning,
      OrderStatus.completed => s.orderStatusCompleted,
      OrderStatus.failed => s.orderStatusFailed,
      OrderStatus.refunded => s.orderStatusRefunded,
    };
  }

  Color get color {
    return switch (this) {
      OrderStatus.created => Colors.grey,
      OrderStatus.paid => Colors.blue,
      OrderStatus.starting => Colors.orange,
      OrderStatus.running => Colors.green,
      OrderStatus.completed => Colors.teal,
      OrderStatus.failed => Colors.red,
      OrderStatus.refunded => Colors.purple,
    };
  }
}

extension WashOrderFlowText on WashOrder {
  String get flowDescription {
    final s = AppStrings.current;
    return switch (status) {
      OrderStatus.created => s.orderFlow1,
      OrderStatus.paid => s.orderFlow2,
      OrderStatus.starting => s.orderFlow3,
      OrderStatus.running => s.orderFlow4,
      OrderStatus.completed => s.orderFlow5,
      OrderStatus.failed => s.orderFlow6,
      OrderStatus.refunded => s.orderFlow7,
    };
  }
}

extension ReservationStatusText on ReservationStatus {
  String get label {
    final s = AppStrings.current;
    return switch (this) {
      ReservationStatus.pending => s.resPending,
      ReservationStatus.arrived => s.resArrived,
      ReservationStatus.completed => s.resCompleted,
      ReservationStatus.cancelled => s.resCancelled,
    };
  }

  Color get color {
    return switch (this) {
      ReservationStatus.pending => Colors.orange,
      ReservationStatus.arrived => Colors.blue,
      ReservationStatus.completed => Colors.green,
      ReservationStatus.cancelled => Colors.grey,
    };
  }
}

extension CarWashStoreSummary on CarWashStore {
  String get serviceSummary {
    return serviceTypes.map((type) => type.label).join(' / ');
  }
}

IconData statusIcon(DeviceStatus status) {
  return switch (status) {
    DeviceStatus.idle => Icons.check_circle_outline,
    DeviceStatus.busy => Icons.local_car_wash,
    DeviceStatus.offline => Icons.cloud_off,
    DeviceStatus.faulted => Icons.warning_amber_outlined,
  };
}

Color statusColor(DeviceStatus status) {
  return switch (status) {
    DeviceStatus.idle => Colors.green,
    DeviceStatus.busy => Colors.blue,
    DeviceStatus.offline => Colors.grey,
    DeviceStatus.faulted => Colors.red,
  };
}

double distanceBetweenKm(LatLng a, LatLng b) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(b.latitude - a.latitude);
  final dLng = _degreesToRadians(b.longitude - a.longitude);
  final lat1 = _degreesToRadians(a.latitude);
  final lat2 = _degreesToRadians(b.latitude);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
  return earthRadiusKm * 2 * atan2(sqrt(h), sqrt(1 - h));
}

double _degreesToRadians(double degrees) => degrees * pi / 180;

int estimateEtaMinutes(double distanceKm) {
  const citySpeedKmPerHour = 24.0;
  return max(3, (distanceKm / citySpeedKmPerHour * 60).round());
}

String formatSeconds(int seconds) {
  final safeSeconds = seconds < 0 ? 0 : seconds;
  final minutes = safeSeconds ~/ 60;
  final remainingSeconds = safeSeconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

String formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDateTime(DateTime time) {
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '$month-$day ${formatTime(time)}';
}

String formatDateOnly(DateTime time) {
  final year = time.year.toString();
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime _todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

List<DateTime> _dateOptions() {
  final today = _todayDateOnly();
  return [for (var i = 0; i < 31; i++) today.add(Duration(days: i))];
}

List<String> _timeOptions() {
  return [
    for (var hour = 0; hour < 24; hour++)
      for (final minute in const [0, 30])
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
  ];
}

String _currentTimeLabel() {
  final now = DateTime.now();
  final minute = now.minute < 30 ? '00' : '30';
  return '${now.hour.toString().padLeft(2, '0')}:$minute';
}

String formatDurationSeconds(int seconds) {
  return AppStrings.current.formatDurationLocalized(seconds);
}

String _newId(String prefix) {
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999)}';
}

void _validateRequired(List<String> values) {
  if (values.any((value) => value.trim().isEmpty)) {
    throw StateError(AppStrings.current.errFillRequired);
  }
}
