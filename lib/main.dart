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
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '清洗到家',
        theme: buildAppTheme(),
        home: const AuthGate(),
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
  AppAccount? currentAccount;
  String? lastReservationPhone;
  String? lastAuthMessage;
  Timer? _washTimer;

  Future<bool> login(String username, String password) async {
    lastAuthMessage = null;
    if (!_shouldUseBackendApi()) {
      return _loginLocal(username, password);
    }
    try {
      await ApiClient.login(username.trim(), password);
      final me = await ApiClient.getMe();
      final account = _upsertAccountFromApi(me, password: password);
      if (account.approvalStatus != ApprovalStatus.approved) {
        if (account.role == AccountRole.shop) {
          currentAccount = account;
          notifyListeners();
          return true;
        }
        lastAuthMessage = account.approvalStatus == ApprovalStatus.pending
            ? '账号正在等待平台审核'
            : '账号审核未通过，请联系平台管理员';
        notifyListeners();
        return false;
      }
      currentAccount = account;
      lastReservationPhone ??= account.phone;
      if (account.role == AccountRole.admin) {
        await syncAccountsFromBackend();
      } else {
        await syncFromBackend();
      }
      notifyListeners();
      return true;
    } on ApiException catch (exception) {
      lastAuthMessage = exception.message;
      notifyListeners();
      return false;
    } on ApiConnectionException {
      return _loginLocal(username, password);
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
                ? '账号正在等待平台审核'
                : '账号审核未通过，请联系平台管理员';
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
    lastAuthMessage = '账号或密码不匹配';
    return false;
  }

  Future<void> syncFromBackend() async {
    if (ApiClient.accessToken == null || currentAccount == null) {
      return;
    }
    try {
      final account = currentAccount!;
      final storeJson = account.role == AccountRole.shop
          ? await ApiClient.fetchMyStores()
          : await ApiClient.fetchStores();
      stores
        ..clear()
        ..addAll(storeJson.map(AppSync.storeFromJson));

      final orderJson = await ApiClient.fetchOrders();
      orders
        ..clear()
        ..addAll(orderJson.map(AppSync.orderFromJson));

      final resJson = await ApiClient.fetchReservations();
      reservations
        ..clear()
        ..addAll(resJson.map(AppSync.reservationFromJson));

      if (account.role == AccountRole.user) {
        final vehicles = await ApiClient.fetchVehicles();
        userVehicles[account.id] =
            vehicles.map(AppSync.vehicleFromJson).toList();
        final addresses = await ApiClient.fetchAddresses();
        userAddresses[account.id] =
            addresses.map(AppSync.addressFromJson).toList();
      }

      if (account.role == AccountRole.shop) {
        final wallet = await ApiClient.fetchWallet();
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
      }
      notifyListeners();
    } on Object {
      // Keep local data if sync fails.
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

  void logout() {
    currentAccount = null;
    ApiClient.accessToken = null;
    notifyListeners();
  }

  Future<AppAccount> registerUser({
    required String countryCode,
    required String phone,
    required String verificationCode,
    required String password,
    required String displayName,
    String referralCode = '',
  }) async {
    if (!_shouldUseBackendApi()) {
      return _registerUserLocal(
        countryCode: countryCode,
        phone: phone,
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
    required String verificationCode,
    required String password,
    required String displayName,
    String referralCode = '',
  }) {
    if (verificationCode.trim() != '0000') {
      throw StateError('验证码错误，测试阶段请填写 0000');
    }
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw StateError('请填写手机号');
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
    required String verificationCode,
    required String password,
    required String storeName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
    required Set<WashServiceType> serviceTypes,
  }) async {
    if (verificationCode.trim() != '1111') {
      throw StateError('验证码错误，测试阶段请填写 1111');
    }
    if (licenseFiles.isEmpty) {
      throw StateError('请上传至少一个经营许可证文件');
    }

    if (!_shouldUseBackendApi()) {
      return _registerShopLocal(
        countryCode: countryCode,
        phone: phone,
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
      throw StateError('验证码错误，测试阶段请填写 1111');
    }
    if (licenseFiles.isEmpty) {
      throw StateError('请上传至少一个经营许可证文件');
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
      throw StateError('只有商家账号可以重新提交材料');
    }
    if (licenseFiles.isEmpty) {
      throw StateError('请上传至少一个经营许可证文件');
    }
    account.displayName = storeName.trim();
    account.shopAddress = address.trim();
    account.shopLatitude = latitude;
    account.shopLongitude = longitude;
    account.licenseFiles = [...licenseFiles];
    account.approvalStatus = ApprovalStatus.pending;
    account.adminReply = '已重新提交材料，等待 Admin 审核。';
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
      throw StateError('请先以商家账号登录');
    }
    if (licenseFiles.isEmpty) {
      throw StateError('请上传至少一个经营许可证文件');
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
      throw StateError('套餐不存在');
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
      throw StateError('只有商家账号可以修改个人信息');
    }
    if (licenseFiles.isEmpty) {
      throw StateError('请上传至少一个经营许可证文件');
    }
    final normalizedUsername = username.trim();
    final normalizedPhone = phone.trim();
    if (normalizedUsername.isEmpty ||
        normalizedPhone.isEmpty ||
        displayName.trim().isEmpty ||
        address.trim().isEmpty) {
      throw StateError('请填写完整信息');
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
      throw StateError('账号已存在，请换一个账号名');
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
      throw StateError('只有用户账号可以使用分享码');
    }
    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final data = await ApiClient.redeemReferral(code);
      _applyApiAccount(forAccount, data);
      notifyListeners();
      return;
    }
    if (forAccount.referredByUserId != null) {
      throw StateError('您已经使用过分享码');
    }
    final referrer = accountByShareCode(code);
    if (referrer == null) {
      throw StateError('分享码无效，请检查后重试');
    }
    if (referrer.id == forAccount.id) {
      throw StateError('不能使用自己的分享码');
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
    return stores.where((store) {
      final owner = accountById(store.ownerAccountId);
      return owner.approvalStatus == ApprovalStatus.approved &&
          store.approvalStatus == ApprovalStatus.approved;
    }).toList(growable: false);
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
      throw StateError('请先以商家身份登录');
    }
    if (amount <= 0) {
      throw StateError('提现金额必须大于 0');
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
      throw StateError('余额不足');
    }
    shopWalletBalances[account.id] = balance - amount;
    walletTransactions.insert(
      0,
      WalletTransaction(
        id: _newId('txn'),
        title: '提现到支付宝',
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

  Future<WashOrder> createPaidOrder({
    required String deviceQrCode,
    required String packageId,
    required bool simulatedPaid,
    bool useFreeWash = false,
    bool usePrepaidWash = false,
  }) async {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.user) {
      throw StateError('请先以用户身份登录');
    }
    final device = deviceByQr(deviceQrCode);
    if (device == null) {
      throw StateError('没有找到这个设备二维码');
    }
    if (device.status != DeviceStatus.idle) {
      throw StateError('设备当前不可用，请选择空闲设备');
    }
    if (useFreeWash && usePrepaidWash) {
      throw StateError('不能同时使用免费次卡和预付次卡');
    }

    final store = storeForDevice(device.id)!;
    final washPackage = packageById(store.id, packageId);

    if (_shouldUseBackendApi() && ApiClient.accessToken != null) {
      final json = await ApiClient.createOrder({
        'store_id': store.id,
        'device_id': device.id,
        'package_id': washPackage.id,
        'amount': washPackage.price,
        'used_free_wash_credit': useFreeWash,
        'used_prepaid_wash_credit': usePrepaidWash,
      });
      final order = AppSync.orderFromJson(json);
      if (useFreeWash) account.freeWashCredits -= 1;
      if (usePrepaidWash) account.prepaidWashCredits -= 1;
      orders.insert(0, order);
      notifyListeners();
      if (simulatedPaid && order.status == OrderStatus.created) {
        final paid = await ApiClient.updateOrder(order.id, {'status': 'paid'});
        final updated = AppSync.orderFromJson(paid);
        final idx = orders.indexWhere((o) => o.id == order.id);
        if (idx >= 0) orders[idx] = updated;
        notifyListeners();
        return updated;
      }
      return order;
    }

    if (useFreeWash && account.freeWashCredits <= 0) {
      throw StateError('没有可用的免费洗车次数');
    }
    if (usePrepaidWash && account.prepaidWashCredits <= 0) {
      throw StateError('没有可用的洗车次卡');
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
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (simulatedPaid) {
      order.status = OrderStatus.paid;
    }
    notifyListeners();
    return order;
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
      order.failureReason = '设备未处于空闲状态，已进入后台异常处理';
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
      throw StateError('请先以用户身份登录');
    }
    final store = storeById(storeId);
    if (!store.serviceTypes.contains(serviceType)) {
      throw StateError('该店铺不支持这个服务类型');
    }
    if (contactPhone.trim().isEmpty) {
      throw StateError('请填写联系电话');
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
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _washTimer?.cancel();
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
        if (account == null) {
          return const AuthPage();
        }
        return switch (account.role) {
          AccountRole.user => const UserShell(),
          AccountRole.shop => account.approvalStatus == ApprovalStatus.approved
              ? const ShopShell()
              : const ShopReviewPage(),
          AccountRole.admin => const AdminShell(),
        };
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            children: [
              Center(child: AppBrandLogo(size: 84)),
              const SizedBox(height: 16),
              Text(
                '清洗到家',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '智慧洗车 · 一键预约 · 轻松管理',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: appSurfaceCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '欢迎登录',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '登录后根据账号角色进入用户 / 商家 / 管理端',
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
                            decoration: const InputDecoration(
                              labelText: '手机号或测试账号',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '手机号登录只输入号码；测试账号 user / shop / admin 不受区号影响。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '密码'),
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
                      onPressed: () async {
                        final ok = await store.login(
                          _loginUsername(),
                          passwordController.text,
                        );
                        if (!ok && mounted) {
                          setState(() => error =
                              store.lastAuthMessage ?? '账号或密码不匹配');
                        }
                      },
                      child: const Text('登录'),
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
                            child: const Text('用户注册'),
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
                            child: const Text('商家注册'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const DemoCredentialCard(),
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
                '演示账号',
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
    final selected = countryCallingCodeForDialCode(value);
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '区号',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selected.displayLabel,
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
                    hintText: '搜索国家/地区或区号',
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
                        '共 ${filteredCodes.length} 个国家/地区',
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
                      return const Center(child: Text('未找到匹配的区号'));
                    }
                    return ListView.builder(
                      itemCount: filteredCodes.length,
                      itemBuilder: (context, index) {
                        final country = filteredCodes[index];
                        return ListTile(
                          title: Text(country.nameZh),
                          subtitle: Text(country.nameEn),
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
            ? '已根据地址更新坐标'
            : '已定位：${result.formattedAddress}';
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
      setState(() => geocodingMessage = '定位失败：$error');
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
        title: const Text('商家注册审核'),
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
          Text('登录账号：${account.username}'),
          if (account.adminReply.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Admin 回复：${account.adminReply}'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppTextField(controller: storeNameController, label: '商户名称'),
          AppTextField(controller: addressController, label: '商户地址'),
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
                  child: AppTextField(controller: latController, label: '纬度')),
              const SizedBox(width: 12),
              Expanded(
                  child: AppTextField(controller: lngController, label: '经度')),
            ],
          ),
          const Text('商户经营许可证', style: TextStyle(fontWeight: FontWeight.w700)),
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
          const Text('服务类型', style: TextStyle(fontWeight: FontWeight.w700)),
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
            label: const Text('修改材料并重新提交审核'),
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
        throw StateError('请上传至少一个经营许可证文件');
      }
      if (serviceTypes.isEmpty) {
        throw StateError('至少选择一种服务类型');
      }
      final latitude = double.tryParse(latController.text.trim());
      final longitude = double.tryParse(lngController.text.trim());
      if (latitude == null || longitude == null) {
        throw StateError('经纬度格式不正确');
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
        const SnackBar(content: Text('材料已重新提交，请等待 Admin 审核')),
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
  final phoneController = TextEditingController();
  final verificationController = TextEditingController();
  final passwordController = TextEditingController();
  final referralController = TextEditingController();
  String countryCode = '+86';
  String? error;
  int _smsCooldown = 0;
  Timer? _smsTimer;

  @override
  void dispose() {
    _smsTimer?.cancel();
    nameController.dispose();
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
      appBar: AppBar(title: const Text('用户注册')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: nameController, label: '姓名'),
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
                      AppTextField(controller: phoneController, label: '手机号')),
            ],
          ),
          AppTextField(
              controller: verificationController, label: '短信验证码'),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _smsCooldown > 0 ? null : _sendSms,
              child: Text(_smsCooldown > 0 ? '${_smsCooldown}s 后重发' : '获取验证码'),
            ),
          ),
          AppTextField(
            controller: passwordController,
            label: '密码',
            obscureText: true,
          ),
          AppTextField(
            controller: referralController,
            label: '好友分享码（选填）',
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: () async {
              try {
                _validateRequired([
                  nameController.text,
                  phoneController.text,
                  verificationController.text,
                  passwordController.text,
                ]);
                await store.registerUser(
                  countryCode: countryCode,
                  phone: phoneController.text,
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
                        '用户注册成功，请使用账号 $countryCode${phoneController.text.trim()} 登录'),
                  ),
                );
              } on Object catch (exception) {
                setState(() => error =
                    exception.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: const Text('注册并登录'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSms() async {
    if (phoneController.text.trim().isEmpty) {
      setState(() => error = '请先填写手机号');
      return;
    }
    try {
      final res = await ApiClient.sendSmsCode(
        countryCode: countryCode,
        phone: phoneController.text,
      );
      final devCode = res['dev_code'] as String?;
      if (devCode != null) {
        verificationController.text = devCode;
      }
      setState(() {
        error = null;
        _smsCooldown = 60;
      });
      _smsTimer?.cancel();
      _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_smsCooldown <= 1) {
          timer.cancel();
          if (mounted) setState(() => _smsCooldown = 0);
        } else if (mounted) {
          setState(() => _smsCooldown -= 1);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] as String? ?? '验证码已发送')),
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
  int _smsCooldown = 0;
  Timer? _smsTimer;

  @override
  void initState() {
    super.initState();
    addressDetailController.addListener(_scheduleGeocode);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleGeocode());
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _smsTimer?.cancel();
    addressDetailController.removeListener(_scheduleGeocode);
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
            ? '已根据地址定位'
            : '已定位：${result.formattedAddress}';
      });
      await shopMapKey.currentState?.moveCamera(result.position, zoom: 16);
    } on GeocodingException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() {
        geocodedLocation = null;
        geocodedAddress = null;
        geocodingMessage =
            '${exception.message}（已使用「${selectedSubArea.nameZh}」默认位置）';
      });
      _syncMapCamera();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        geocodedLocation = null;
        geocodedAddress = null;
        geocodingMessage = '定位失败，已使用区域默认位置（$error）';
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
      appBar: AppBar(title: const Text('商家注册')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(controller: storeNameController, label: '商户名称'),
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
                      controller: phoneController, label: '商户电话号码')),
            ],
          ),
          AppTextField(
              controller: verificationController, label: '短信验证码'),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _smsCooldown > 0 ? null : _sendSms,
              child: Text(
                  _smsCooldown > 0 ? '${_smsCooldown}s 后重发' : '获取验证码'),
            ),
          ),
          AppTextField(
            controller: passwordController,
            label: '密码',
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
            '地址预览：$locationLabel${addressDetailController.text.trim().isEmpty ? '' : ' · ${addressDetailController.text.trim()}'}',
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
            '坐标：${mapLocation.latitude.toStringAsFixed(6)}, ${mapLocation.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const Text('商户经营许可证', style: TextStyle(fontWeight: FontWeight.w700)),
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
          const Text('服务类型', style: TextStyle(fontWeight: FontWeight.w700)),
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
                        phoneController.text,
                        verificationController.text,
                        passwordController.text,
                      ]);
                      if (licenseFiles.isEmpty) {
                        throw StateError('请上传至少一个经营许可证文件');
                      }
                      if (serviceTypes.isEmpty) {
                        throw StateError('至少选择一种服务类型');
                      }
                      setState(() {
                        submitting = true;
                        error = null;
                      });
                      await store.registerShop(
                        countryCode: countryCode,
                        phone: phoneController.text,
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
                        const SnackBar(content: Text('商家注册已提交，请等待 Admin 审核')),
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
            child: Text(submitting ? '提交中…' : '注册商家并加入地图'),
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

  Future<void> _sendSms() async {
    if (phoneController.text.trim().isEmpty) {
      setState(() => error = '请先填写手机号');
      return;
    }
    try {
      final res = await ApiClient.sendSmsCode(
        countryCode: countryCode,
        phone: phoneController.text,
      );
      final devCode = res['dev_code'] as String?;
      if (devCode != null) {
        verificationController.text = devCode;
      }
      setState(() {
        error = null;
        _smsCooldown = 60;
      });
      _smsTimer?.cancel();
      _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_smsCooldown <= 1) {
          timer.cancel();
          if (mounted) setState(() => _smsCooldown = 0);
        } else if (mounted) {
          setState(() => _smsCooldown -= 1);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] as String? ?? '验证码已发送')),
        );
      }
    } on Object catch (e) {
      setState(() => error = e.toString());
    }
  }
}

/// 切换用户端底部导航 Tab（0 洗车 / 1 预约 / 2 订单 / 3 我的）
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

  @override
  Widget build(BuildContext context) {
    const pages = [
      UserHomePage(),
      UserReservationsPage(),
      UserOrdersPage(),
      UserProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      floatingActionButton: FloatingActionButton.large(
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
              const SnackBar(content: Text('未识别的二维码，请扫描洗车设备码')),
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
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_car_wash_outlined),
            selectedIcon: Icon(Icons.local_car_wash),
            label: '洗车',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '预约',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '订单',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '个人中心',
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
            const SectionTitle(
              title: '我的预约',
              subtitle: '选择门店并填写信息，即可提交到店预约。',
            ),
            const SizedBox(height: 12),
            if (stores.isEmpty)
              const EmptyState(
                icon: Icons.storefront_outlined,
                title: '暂无可预约门店',
                description: '请稍后再试，或先在洗车页查看附近门店。',
              )
            else
              ReservationFormCard(
                stores: stores,
                userLocation: fallbackUserLocation,
              ),
            const SizedBox(height: 20),
            const Text('预约记录', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (reservations.isEmpty)
              const EmptyState(
                icon: Icons.calendar_month_outlined,
                title: '暂无预约',
                description: '填写上方表单即可提交第一条预约。',
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
            const Text('新建预约', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedStoreId,
              decoration: const InputDecoration(
                labelText: '选择门店',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final store in widget.stores)
                  DropdownMenuItem(
                    value: store.id,
                    child: Text(
                      store.name,
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
              '距离约 ${distanceKm.toStringAsFixed(1)} km，预计 ${estimateEtaMinutes(distanceKm)} 分钟到达',
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
                  value: selectedDate,
                  decoration: const InputDecoration(
                    labelText: '预约日期',
                    border: OutlineInputBorder(),
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
                  value: selectedTime,
                  decoration: const InputDecoration(
                    labelText: '预约时间',
                    border: OutlineInputBorder(),
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
            AppTextField(controller: phoneController, label: '联系电话'),
            const SizedBox(height: 8),
            const Text('预约类型', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final type in sortedWashServiceTypes(selectedStore.serviceTypes))
              RadioListTile<WashServiceType>(
                value: type,
                groupValue: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
                dense: true,
                title: Text(type.label),
                subtitle: washServiceTypeSubtitle(
                  type,
                  manualHint: '商家人工接待与精洗',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            if (selectedType == WashServiceType.selfService)
              const SelfServiceEcoBanner(),
            TextField(
              controller: noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注，例如车型、洗车需求',
                border: OutlineInputBorder(),
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
                        '预约已提交，预计 ${reservation.etaMinutes} 分钟到达',
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
              label: const Text('提交预约'),
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
  String locationMessage = '正在获取定位...';

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final visibleStores = store.approvedStores();
    final sortedStores = [...visibleStores]..sort(
        (a, b) => distanceBetweenKm(userLocation, a.position).compareTo(
          distanceBetweenKm(userLocation, b.position),
        ),
      );
    final markers = {
      Marker(
        markerId: const MarkerId('me'),
        position: userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(title: '我的位置'),
      ),
      for (final washStore in visibleStores)
        Marker(
          markerId: MarkerId(washStore.id),
          position: washStore.position,
          infoWindow: InfoWindow(
            title: washStore.name,
            snippet: washStore.serviceSummary,
          ),
          onTap: () => setState(() => selectedStore = washStore),
        ),
    };
    final polylines = {
      if (selectedStore != null)
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: [userLocation, selectedStore!.position],
        ),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle(
          title: '洗车',
          subtitle: '地图显示附近洗车店，支持自助扫码洗车与到店预约。',
        ),
        if (store.runningOrder != null) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.primarySurface,
            child: ListTile(
              leading: const AppIconBadge(
                icon: Icons.local_car_wash,
                size: 44,
              ),
              title: const Text(
                '您有进行中的订单',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('点击查看详情'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final parent =
                    context.findAncestorStateOfType<_UserShellState>();
                parent?.setState(() => parent.index = 2);
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        CarWashMapView(
          key: mapKey,
          height: 220,
          cameraTarget: userLocation,
          markers: markers,
          polylines: polylines,
          onTap: (_) {},
        ),
        const SizedBox(height: 8),
        Text(locationMessage),
        if (locating) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
        if (store.currentAccount?.role == AccountRole.user) ...[
          const SizedBox(height: 12),
          ShareReferralPanel(
            shareCode: store.currentAccount!.shareCode,
            canShare: store.canShareReferral(store.currentAccount!),
            freeWashCredits: store.currentAccount!.freeWashCredits,
          ),
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
        const Text('附近门店', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (sortedStores.isEmpty)
          const EmptyState(
            icon: Icons.store_outlined,
            title: '暂无门店',
            description: '当前没有已审核通过的洗车店。',
          )
        else
          for (final washStore in sortedStores) ...[
            StoreCard(
              store: washStore,
              distanceKm: distanceBetweenKm(userLocation, washStore.position),
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
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Future<void> _loadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          locating = false;
          locationMessage = '定位服务未开启，使用香港中西区默认位置。';
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          locating = false;
          locationMessage = '未获得定位权限，使用香港中西区默认位置。';
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = location;
        locating = false;
        locationMessage = '已获取当前位置，列表按距离由近到远排序。';
      });
      await mapKey.currentState?.moveCamera(location);
    } on Object {
      setState(() {
        locating = false;
        locationMessage = '定位失败，使用香港中西区默认位置。';
      });
    }
  }

  Future<void> _focusStore(CarWashStore store) async {
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
                '已选择 ${store.name}：约 ${distanceKm.toStringAsFixed(1)} km，预计 ${estimateEtaMinutes(distanceKm)} 分钟到达。点击店铺卡片的“Google导航”可跳转导航。',
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
                    store.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text('${distanceKm.toStringAsFixed(1)} km'),
              ],
            ),
            const SizedBox(height: 6),
            Text(store.address),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(icon: Icons.star, label: store.rating.toString()),
                InfoChip(icon: Icons.event_available, label: '$idleCount 空闲'),
                for (final type in store.serviceTypes)
                  InfoChip(label: type.label, icon: type.icon),
                for (final tag in store.tags) InfoChip(label: tag),
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
                  label: const Text('查看地图'),
                ),
                OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Google导航'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onReserve,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('预约到店'),
                ),
                FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('扫码洗车'),
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
      appBar: AppBar(title: const Text('预约到店')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(
            title: widget.store.name,
            subtitle:
                '距离 ${distanceKm.toStringAsFixed(1)} km，预计 ${estimateEtaMinutes(distanceKm)} 分钟到达。',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final dateField = DropdownButtonFormField<DateTime>(
                isExpanded: true,
                value: selectedDate,
                decoration: const InputDecoration(
                  labelText: '预约日期',
                  border: OutlineInputBorder(),
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
                value: selectedTime,
                decoration: const InputDecoration(
                  labelText: '预约时间',
                  border: OutlineInputBorder(),
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
          AppTextField(controller: phoneController, label: '联系电话'),
          const SizedBox(height: 8),
          const Text('选择预约类型', style: TextStyle(fontWeight: FontWeight.w700)),
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
                manualHint: '商家人工接待与精洗',
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
            decoration: const InputDecoration(
              labelText: '备注，例如车型、洗车需求',
              border: OutlineInputBorder(),
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
                      content: Text('预约已提交，预计 ${reservation.etaMinutes} 分钟到达')),
                );
              } on StateError catch (exception) {
                setState(() => error = exception.message);
              } on Object catch (exception) {
                setState(() => error = exception.toString());
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('提交预约'),
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
  bool simulatedPaid = true;
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
    final availableStores = appStore.approvedStores();
    final packages = selectedStore?.packages ?? availableStores.first.packages;
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
      appBar: AppBar(title: const Text('扫码支付')),
      body: AnimatedBuilder(
        animation: appStore,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionTitle(
                title: '扫码洗车',
                subtitle: '扫描设备二维码，选择套餐后支付或使用次卡。',
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
                label: const Text('重新扫码'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: qrCode,
                decoration: const InputDecoration(
                  labelText: '当前设备',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final store in availableStores)
                    for (final device in store.devices)
                      DropdownMenuItem(
                        value: device.qrCode,
                        child: Text(
                          '${device.qrCode} - ${store.name} ${device.bayName}',
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
                          .withOpacity(0.5),
                  child: SwitchListTile(
                    title: Text(
                      canUseFreeWash
                          ? '使用免费洗车（剩余 $freeWashCredits 次）'
                          : '使用免费洗车（暂无可用次数）',
                      style: TextStyle(
                        color: canUseFreeWash
                            ? null
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    subtitle: Text(
                      canUseFreeWash
                          ? '开启后本单实付款 ¥0，关闭则按套餐原价支付'
                          : '完成分享或兑换后可获得免费洗车次数',
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
                          .withOpacity(0.5),
                  child: SwitchListTile(
                    title: Text(
                      canUsePrepaid
                          ? '使用洗车次卡（剩余 $prepaidCredits 次）'
                          : '暂无洗车次卡',
                    ),
                    subtitle: Text(
                      canUsePrepaid
                          ? '开启后本单免支付，优先消耗次卡'
                          : '可在个人中心购买次卡套餐',
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
              const Text('选择套餐', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  title: const Text('实付款'),
                  trailing: Text(
                    '¥${actualAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: useFreeWashThisOrder && canUseFreeWash
                      ? Text(
                          '原价 ¥${selectedPackage.price.toStringAsFixed(0)}，已使用免费洗车',
                        )
                      : usePrepaidWashThisOrder && canUsePrepaid
                          ? Text(
                              '原价 ¥${selectedPackage.price.toStringAsFixed(0)}，已使用洗车次卡',
                            )
                          : null,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: simulatedPaid,
                onChanged: isProcessing
                    ? null
                    : (value) => setState(() => simulatedPaid = value),
                title: const Text('模拟已扫码并已付款'),
                subtitle: const Text('打开后会直接新增订单并激活洗车流程。'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed:
                    isProcessing ? null : () => _payAndStart(context, appStore),
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(isProcessing ? '处理中...' : '创建订单并进入洗车流程'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _payAndStart(BuildContext context, AppStore appStore) async {
    setState(() {
      isProcessing = true;
      error = null;
    });
    try {
      final order = await appStore.createPaidOrder(
        deviceQrCode: qrCode,
        packageId: selectedPackageId,
        simulatedPaid: simulatedPaid,
        useFreeWash: useFreeWashThisOrder,
        usePrepaidWash: usePrepaidWashThisOrder,
      );
      if (simulatedPaid) {
        await appStore.startOrder(order);
      }
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('订单 ${order.id} 已创建')));
    } on StateError catch (exception) {
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
            const SectionTitle(
              title: '我的订单',
              subtitle: '跟踪支付、启动、洗车中、完成和异常状态。',
            ),
            const SizedBox(height: 12),
            if (userOrders.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: '还没有订单',
                description: '在洗车页选择门店并扫码支付。',
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

  @override
  Widget build(BuildContext context) {
    const pages = [
      ShopStoresPage(),
      ShopReservationsPage(),
      ShopProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: '店铺',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '预约',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
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
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final stores = appStore.storesForCurrentShop();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TopBar(
              title: 'Shop 商家端',
              subtitle:
                  '${appStore.currentAccount?.displayName ?? ''}，管理店铺、工位状态和工位统计。',
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddShopStorePage()),
              ),
              icon: const Icon(Icons.add_business),
              label: const Text('添加新的店铺'),
            ),
            const SizedBox(height: 12),
            for (final store in stores) ...[
              ShopStoreCard(store: store, showAddBay: true),
              const SizedBox(height: 12),
            ],
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
            const TopBar(title: '预约表单', subtitle: '按店铺筛选用户提交的预约。'),
            StoreFilterDropdown(
              stores: stores,
              value: selectedStoreId,
              onChanged: (value) => setState(() => selectedStoreId = value),
            ),
            const SizedBox(height: 12),
            if (reservations.isEmpty)
              const EmptyState(
                icon: Icons.calendar_month_outlined,
                title: '暂无预约',
                description: '用户提交预约到店后会显示在这里。',
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
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        final stores = appStore.storesForCurrentShop();
        final orders = appStore.ordersForCurrentShop().where((item) {
          return selectedStoreId == 'all' || item.storeId == selectedStoreId;
        }).toList();
        final completed = orders
            .where((order) => order.status == OrderStatus.completed)
            .length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TopBar(
              title: '商家订单',
              subtitle: '按店铺筛选订单，查看完成数量和洗车流程状态。',
            ),
            StoreFilterDropdown(
              stores: stores,
              value: selectedStoreId,
              onChanged: (value) => setState(() => selectedStoreId = value),
            ),
            const SizedBox(height: 12),
            MetricCard(
                label: '已完成订单',
                value: '$completed / ${orders.length}',
                icon: Icons.done_all),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: '暂无订单',
                description: '用户扫码付款后订单会显示在这里。',
              )
            else
              for (final order in orders) ...[
                OrderCard(order: order),
                const SizedBox(height: 8),
              ],
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminApprovalPage(onQueueChanged: _refreshPendingCount),
      const AdminOverviewPage(),
      const AdminStoresPage(),
      const AdminReservationsPage(),
      const AdminOrdersPage(),
      const AdminPricingPage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
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
            label: '审核',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '总览',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: '店铺',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '预约',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '订单',
          ),
          const NavigationDestination(
            icon: Icon(Icons.price_change_outlined),
            selectedIcon: Icon(Icons.price_change),
            label: '定价',
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
      title: Text('修改「${washPackage.name}」'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '价格（元）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: minutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '时长（分钟）',
              border: OutlineInputBorder(),
            ),
          ),
        ],
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
    minutesController.dispose();
    return;
  }
  try {
    final price = double.tryParse(priceController.text.trim());
    final minutes = int.tryParse(minutesController.text.trim());
    if (price == null || price < 0) {
      throw StateError('价格格式不正确');
    }
    if (minutes == null || minutes <= 0) {
      throw StateError('时长格式不正确');
    }
    await appStore.updateStorePackage(
      storeId: store.id,
      packageId: washPackage.id,
      price: price,
      minutes: minutes,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('套餐价格已更新')),
      );
    }
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
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
            const TopBar(title: 'Admin 平台端', subtitle: '平台总览和关键指标。'),
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
                    label: '用户',
                    value:
                        '${appStore.accounts.where((a) => a.role == AccountRole.user).length}',
                    icon: Icons.person),
                MetricCard(
                    label: '商家',
                    value:
                        '${appStore.accounts.where((a) => a.role == AccountRole.shop).length}',
                    icon: Icons.store),
                MetricCard(
                    label: '地图点',
                    value: '${appStore.stores.length}',
                    icon: Icons.location_on),
                MetricCard(
                    label: '预约',
                    value: '${appStore.reservations.length}',
                    icon: Icons.calendar_month),
                MetricCard(
                    label: '订单',
                    value: '${appStore.orders.length}',
                    icon: Icons.receipt_long),
                MetricCard(
                    label: '异常设备',
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
              const TopBar(title: '账号管理', subtitle: '管理用户账号和商家注册信息。'),
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
                      tooltip: '从后端刷新',
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
              const Text('用户账号管理', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final account in appStore.accounts
                  .where((item) => item.role == AccountRole.user))
                AccountApprovalCard(account: account),
              const SizedBox(height: 16),
              const Text('商家账号管理', style: TextStyle(fontWeight: FontWeight.w800)),
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
            Text('${account.role.label} · 手机/账号：${account.phone}'),
            if (account.role == AccountRole.shop)
              for (final store in appStore.stores.where(
                (store) => store.ownerAccountId == account.id,
              ))
                Text('店铺：${store.name} · ${store.address}'),
            if (account.role == AccountRole.shop &&
                account.licenseFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_open),
                title: Text('查看许可证材料（${account.licenseFiles.length}）'),
                subtitle: Text(account.licenseFiles.join('，')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LicenseMaterialsPage(
                        title: '${account.displayName} · 许可证材料',
                        files: account.licenseFiles,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (account.adminReply.isNotEmpty)
              Text('Admin 回复：${account.adminReply}'),
            if (account.role != AccountRole.admin) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => appStore.updateAccountApproval(
                      account,
                      ApprovalStatus.approved,
                      adminReply: '审核通过',
                    ),
                    child: const Text('批准'),
                  ),
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(context, appStore),
                    child: const Text('拒绝并回复'),
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
          title: const Text('审核回复'),
          content: TextField(
            controller: replyController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '请输入需要商家修改或补充的材料',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(replyController.text),
              child: const Text('拒绝并发送'),
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
      adminReply: reply.trim().isEmpty ? '请修改或补充注册材料' : reply,
    );
  }
}

class AdminStoresPage extends StatelessWidget {
  const AdminStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TopBar(title: '店铺和工位', subtitle: '包含商家端全部店铺和工位统计信息。'),
            for (final store in appStore.stores) ...[
              ShopStoreCard(store: store),
              const SizedBox(height: 12),
            ],
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
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TopBar(title: '全部预约', subtitle: '查看所有商家的预约表单。'),
            if (appStore.reservations.isEmpty)
              const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: '暂无预约',
                  description: '用户预约后会出现在这里。')
            else
              for (final reservation in appStore.reservations) ...[
                ReservationCard(reservation: reservation, showActions: true),
                const SizedBox(height: 8),
              ],
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
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TopBar(title: '全部订单', subtitle: '查看所有商家的订单和洗车流程。'),
            if (appStore.orders.isEmpty)
              const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: '暂无订单',
                  description: '用户扫码付款后订单会出现在这里。')
            else
              for (final order in appStore.orders) ...[
                OrderCard(order: order),
                const SizedBox(height: 8),
              ],
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
      value: value,
      decoration: const InputDecoration(
        labelText: '店铺筛选',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('全部店铺')),
        for (final store in stores)
          DropdownMenuItem(
            value: store.id,
            child: Text(
              store.name,
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
              title: '个人中心',
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
              label: const Text('退出登录'),
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
      child: Row(
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
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: appStore.logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: '退出登录',
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
                    store.name,
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
              '用户：${user.displayName} ${reservation.contactPhone}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text('预约类型：${reservation.serviceType.label}'),
            Text('预约到店：${formatDateTime(reservation.arrivalTime)}'),
            Text(
              '预计 ${reservation.etaMinutes} 分钟到达，距离 ${reservation.distanceKm.toStringAsFixed(1)} km',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (reservation.note.isNotEmpty)
              Text(
                '备注：${reservation.note}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            Text('提交时间：${formatTime(reservation.createdAt)}'),
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
                    store.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (store.approvalStatus == ApprovalStatus.pending)
                  const StatusPill(text: '待审核', color: Colors.red)
                else if (store.approvalStatus == ApprovalStatus.rejected)
                  const StatusPill(text: '已驳回', color: Colors.grey),
              ],
            ),
            if (store.adminReply.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '平台意见：${store.adminReply}',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const SizedBox(height: 6),
            Text(store.address),
            Text('服务类型：${store.serviceSummary}'),
            const SizedBox(height: 8),
            const Text('洗车套餐价格', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final washPackage in store.packages)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(washPackage.name),
                subtitle: Text('${washPackage.minutes} 分钟'),
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
                label: const Text('添加洗车位'),
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
                              '${device.bayName} · ${device.status.label}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          PopupMenuButton<DeviceStatus>(
                            onSelected: (status) {
                              appStore.markDeviceStatus(device.id, status);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: DeviceStatus.idle,
                                child: Text('设为在线空闲'),
                              ),
                              PopupMenuItem(
                                value: DeviceStatus.offline,
                                child: Text('设为离线'),
                              ),
                              PopupMenuItem(
                                value: DeviceStatus.faulted,
                                child: Text('设为故障'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '使用次数 ${device.useCount} · 使用时长 ${formatDurationSeconds(device.totalUseSeconds)} · 故障次数 ${device.faultCount}',
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
      appBar: AppBar(title: const Text('添加洗车位')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.store.name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          AppTextField(
              controller: bayNameController, label: '工位名称，例如 自助4号 / 人工1号'),
          DropdownButtonFormField<WashServiceType>(
            value: serviceType,
            decoration: const InputDecoration(
              labelText: '工位类型',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                  value: WashServiceType.selfService, child: Text('自助洗车位')),
              DropdownMenuItem(
                  value: WashServiceType.manual, child: Text('人工洗车位')),
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
            child: const Text('添加工位'),
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
            ? '已根据地址更新坐标'
            : '已定位：${result.formattedAddress}';
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
      setState(() => geocodingMessage = '定位失败：$error');
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
      appBar: AppBar(title: const Text('添加新的店铺')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('商户电话账号：$phone（不可修改）'),
          const SizedBox(height: 12),
          AppTextField(controller: storeNameController, label: '店铺名称'),
          AppTextField(controller: addressController, label: '店铺地址'),
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
                  child: AppTextField(controller: latController, label: '纬度')),
              const SizedBox(width: 12),
              Expanded(
                  child: AppTextField(controller: lngController, label: '经度')),
            ],
          ),
          const Text('经营许可证材料', style: TextStyle(fontWeight: FontWeight.w700)),
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
          const Text('服务类型', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  throw StateError('请上传至少一个经营许可证文件');
                }
                if (serviceTypes.isEmpty) {
                  throw StateError('至少选择一种服务类型');
                }
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null || lng == null) {
                  throw StateError('经纬度格式不正确');
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
                  const SnackBar(content: Text('门店已提交，等待平台审核')),
                );
              } on Object catch (exception) {
                setState(() => error =
                    exception.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: const Text('提交新店铺'),
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
            label: Text('${device.bayName} ${device.status.label}'),
          ),
      ],
    );
  }
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
              store.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('${device.bayName} · ${device.status.label}'),
            const SizedBox(height: 8),
            Text('地址：${store.address}'),
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
                      '${package.name}  ¥${price.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('${package.minutes} 分钟 · ${package.description}'),
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
                    washPackage.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                StatusPill(text: order.status.label, color: order.status.color),
              ],
            ),
            const SizedBox(height: 8),
            Text(store.name),
            Text(
              order.usedFreeWashCredit
                  ? '${device.bayName} · 免费洗车'
                  : '${device.bayName} · ¥${order.amount.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 6),
            Text('流程：${order.flowDescription}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress(washPackage, order)),
            const SizedBox(height: 8),
            Text(
              order.status == OrderStatus.running
                  ? '剩余 ${formatSeconds(order.remainingSeconds)}'
                  : '订单号：${order.id}',
            ),
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
                label: const Text('模拟付款并启动'),
              ),
            ],
            if (isAdmin && order.status == OrderStatus.running) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => appStore.finishOrder(order),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('结束洗车'),
              ),
            ],
          ],
        ),
      ),
    );
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
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
    return switch (this) {
      AccountRole.user => '用户',
      AccountRole.shop => '商家',
      AccountRole.admin => '平台管理员',
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
    return switch (this) {
      ApprovalStatus.pending => '待审核',
      ApprovalStatus.approved => '已批准',
      ApprovalStatus.rejected => '已拒绝',
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
    return switch (this) {
      WashServiceType.selfService => '自助洗车',
      WashServiceType.manual => '人工洗车',
    };
  }

  String? get ecoSubtitle {
    return switch (this) {
      WashServiceType.selfService =>
        '每一次自助洗车节省约 60 升到 100 升的水，为环保贡献一份力量！',
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
    return switch (this) {
      DeviceStatus.idle => '空闲',
      DeviceStatus.busy => '使用中',
      DeviceStatus.offline => '离线',
      DeviceStatus.faulted => '故障',
    };
  }
}

extension OrderStatusText on OrderStatus {
  String get label {
    return switch (this) {
      OrderStatus.created => '待支付',
      OrderStatus.paid => '已支付',
      OrderStatus.starting => '启动中',
      OrderStatus.running => '洗车中',
      OrderStatus.completed => '已完成',
      OrderStatus.failed => '异常',
      OrderStatus.refunded => '已退款',
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
    return switch (status) {
      OrderStatus.created => '1. 已创建订单，等待扫码或线上付款',
      OrderStatus.paid => '2. 已付款，等待设备启动',
      OrderStatus.starting => '3. 正在向设备发送启动指令',
      OrderStatus.running => '4. 洗车中，请按设备提示完成清洗',
      OrderStatus.completed => '5. 洗车完成，订单已结束',
      OrderStatus.failed => '异常：设备启动失败或订单异常',
      OrderStatus.refunded => '已退款，流程结束',
    };
  }
}

extension ReservationStatusText on ReservationStatus {
  String get label {
    return switch (this) {
      ReservationStatus.pending => '待到店',
      ReservationStatus.arrived => '已到店',
      ReservationStatus.completed => '已完成',
      ReservationStatus.cancelled => '已取消',
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
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes分$remaining秒';
}

String _newId(String prefix) {
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999)}';
}

void _validateRequired(List<String> values) {
  if (values.any((value) => value.trim().isEmpty)) {
    throw StateError('请填写所有必填信息');
  }
}
