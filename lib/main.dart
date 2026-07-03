import 'dart:async';
import 'dart:math';

import 'package:car_washing_app/car_wash_map.dart';
import 'package:car_washing_app/country_codes.dart';
import 'package:car_washing_app/hk_district_picker.dart';
import 'package:car_washing_app/hk_districts.dart';
import 'package:car_washing_app/hk_sub_areas.dart';
import 'package:car_washing_app/payment/payment_models.dart';
import 'package:car_washing_app/payment/payment_page.dart';
import 'package:car_washing_app/share_referral.dart';
import 'package:flutter/foundation.dart';
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0ea5e9)),
          useMaterial3: true,
        ),
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
        reservations = [];

  final List<AppAccount> accounts;
  final List<CarWashStore> stores;
  final List<WashOrder> orders;
  final List<Reservation> reservations;
  AppAccount? currentAccount;
  String? lastReservationPhone;
  String? lastAuthMessage;
  Timer? _washTimer;

  bool login(String username, String password) {
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

  void logout() {
    currentAccount = null;
    notifyListeners();
  }

  AppAccount registerUser({
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

  AppAccount registerShop({
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
      throw StateError('请上传或填写至少一个经营许可证文件');
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
      throw StateError('请上传或填写至少一个经营许可证文件');
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

  CarWashStore addStoreForCurrentShop({
    required String storeName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
    required Set<WashServiceType> serviceTypes,
  }) {
    final account = currentAccount;
    if (account == null || account.role != AccountRole.shop) {
      throw StateError('请先以商家账号登录');
    }
    if (licenseFiles.isEmpty) {
      throw StateError('请上传或填写至少一个经营许可证文件');
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
    );
    stores.add(store);
    account.licenseFiles = {...account.licenseFiles, ...licenseFiles}.toList();
    notifyListeners();
    return store;
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

  void redeemReferralCode(String code, {required AppAccount forAccount}) {
    if (forAccount.role != AccountRole.user) {
      throw StateError('只有用户账号可以使用分享码');
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
      return owner.approvalStatus == ApprovalStatus.approved;
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

  double get todayRevenue => orders
      .where((order) => order.status == OrderStatus.completed)
      .fold<double>(0, (sum, order) => sum + order.amount);

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

    final store = storeForDevice(device.id)!;
    final washPackage = packageById(store.id, packageId);
    if (useFreeWash && account.freeWashCredits <= 0) {
      throw StateError('没有可用的免费洗车次数');
    }
    if (useFreeWash) {
      account.freeWashCredits -= 1;
    }
    final useFreeWashCredit = useFreeWash;
    final order = WashOrder(
      id: _newId('CW'),
      userAccountId: account.id,
      storeId: store.id,
      deviceId: device.id,
      packageId: washPackage.id,
      status: OrderStatus.created,
      amount: useFreeWashCredit ? 0 : washPackage.price,
      createdAt: DateTime.now(),
      remainingSeconds: washPackage.minutes * 60,
      usedFreeWashCredit: useFreeWashCredit,
    );
    orders.insert(0, order);
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
      orElse: () => throw StateError('找不到订单'),
    );
    if (order.status != OrderStatus.created) {
      throw StateError('订单状态不可付款');
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

  Reservation createReservation({
    required String storeId,
    required WashServiceType serviceType,
    required LatLng userLocation,
    required DateTime arrivalTime,
    required String contactPhone,
    required String note,
  }) {
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

  void updateReservationStatus(
    Reservation reservation,
    ReservationStatus status,
  ) {
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.local_car_wash, size: 70, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              '清洗到家',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '登录后会根据账号角色自动进入 User / Shop / Admin 端',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
                  child: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: '手机号或测试账号',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '手机号登录只输入号码；测试账号 user / shop / admin 不受区号影响。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final ok = store.login(
                  _loginUsername(),
                  passwordController.text,
                );
                if (!ok) {
                  setState(() => error = store.lastAuthMessage ?? '账号或密码不匹配');
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
            const SizedBox(height: 20),
            const DemoCredentialCard(),
          ],
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
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('演示账号', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('User: user / 123456'),
            Text('Shop: shop / 123456'),
            Text('Admin: admin / 123456'),
          ],
        ),
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
  final licenseController = TextEditingController();
  final serviceTypes = <WashServiceType>{};
  final licenseFiles = <String>[];
  bool initialized = false;
  String? error;

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
    storeNameController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    licenseController.dispose();
    super.dispose();
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
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: licenseController,
                  label: '补充文件名或路径，支持 pdf/jpg/png',
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonal(
                  onPressed: _addLicenseFile,
                  child: const Text('添加'),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final file in licenseFiles)
                InputChip(
                  label: Text(file),
                  onDeleted: () => setState(() => licenseFiles.remove(file)),
                ),
            ],
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
              subtitle: type.ecoSubtitle == null
                  ? null
                  : Text(
                      type.ecoSubtitle!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              secondary: Icon(type.icon),
            ),
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

  void _addLicenseFile() {
    final file = licenseController.text.trim();
    final lower = file.toLowerCase();
    if (file.isEmpty) {
      setState(() => error = '请填写文件名或路径');
      return;
    }
    if (file == '1111') {
      setState(() {
        licenseFiles.add('mock-business-license.pdf');
        licenseController.clear();
        error = null;
      });
      return;
    }
    if (!(lower.endsWith('.pdf') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png'))) {
      setState(() => error = '许可证文件支持 pdf、jpg、jpeg、png；测试可填写 1111');
      return;
    }
    setState(() {
      licenseFiles.add(file);
      licenseController.clear();
      error = null;
    });
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
      _collectLicenseInputIfPresent();
      _validateRequired([
        storeNameController.text,
        addressController.text,
        latController.text,
        lngController.text,
      ]);
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

  void _collectLicenseInputIfPresent() {
    final file = licenseController.text.trim();
    if (file.isEmpty) {
      return;
    }
    if (file == '1111') {
      licenseFiles.add('mock-business-license.pdf');
      licenseController.clear();
      return;
    }
    final lower = file.toLowerCase();
    if (lower.endsWith('.pdf') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png')) {
      licenseFiles.add(file);
      licenseController.clear();
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

  @override
  void dispose() {
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
              controller: verificationController, label: '验证码（测试填写 0000）'),
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
            onPressed: () {
              try {
                _validateRequired([
                  nameController.text,
                  phoneController.text,
                  verificationController.text,
                  passwordController.text,
                ]);
                store.registerUser(
                  countryCode: countryCode,
                  phone: phoneController.text,
                  verificationCode: verificationController.text,
                  password: passwordController.text,
                  displayName: nameController.text,
                  referralCode: referralController.text,
                );
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
  final licenseController = TextEditingController();
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

  @override
  void dispose() {
    phoneController.dispose();
    verificationController.dispose();
    passwordController.dispose();
    storeNameController.dispose();
    addressDetailController.dispose();
    licenseController.dispose();
    super.dispose();
  }

  LatLng get selectedLocation => latLngForHkSelection(
        district: selectedDistrict,
        subArea: selectedSubArea,
      );

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
    shopMapKey.currentState?.moveCamera(selectedLocation, zoom: 14);
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
    _syncMapCamera();
  }

  void _onDistrictChanged(HkDistrict district) {
    final subAreas = hkSubAreasForDistrict(district.nameZh);
    setState(() {
      selectedDistrict = district;
      selectedSubArea = subAreas.first;
    });
    _syncMapCamera();
  }

  void _onSubAreaChanged(HkSubArea subArea) {
    setState(() => selectedSubArea = subArea);
    _syncMapCamera();
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
              controller: verificationController, label: '验证码（测试填写 1111）'),
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
          ),
          const SizedBox(height: 12),
          CarWashMapView(
            key: shopMapKey,
            height: 180,
            borderRadius: 16,
            cameraTarget: selectedLocation,
            zoom: 14,
            myLocationEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('shop-location'),
                position: selectedLocation,
                infoWindow: InfoWindow(title: selectedSubArea.nameZh),
              ),
            },
          ),
          const SizedBox(height: 8),
          Text(
            '地址预览：$locationLabel${addressDetailController.text.trim().isEmpty ? '' : ' · ${addressDetailController.text.trim()}'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (kDebugMode) const MapSetupHintBanner(),
          const SizedBox(height: 12),
          const Text('商户经营许可证', style: TextStyle(fontWeight: FontWeight.w700)),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: licenseController,
                  label: '文件名/路径，测试可填 1111',
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonal(
                  onPressed: _addLicenseFile,
                  child: const Text('添加'),
                ),
              ),
            ],
          ),
          if (licenseFiles.isEmpty)
            const Text('请添加 pdf、jpg、jpeg、png 等许可证材料；测试可填写 1111')
          else
            Wrap(
              spacing: 8,
              children: [
                for (final file in licenseFiles)
                  InputChip(
                    label: Text(file),
                    onDeleted: () => setState(() => licenseFiles.remove(file)),
                  ),
              ],
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
              subtitle: type.ecoSubtitle == null
                  ? null
                  : Text(
                      type.ecoSubtitle!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              secondary: Icon(type.icon),
            ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: () {
              try {
                _collectLicenseInputIfPresent();
                _validateRequired([
                  storeNameController.text,
                  phoneController.text,
                  verificationController.text,
                  passwordController.text,
                ]);
                if (serviceTypes.isEmpty) {
                  throw StateError('至少选择一种服务类型');
                }
                store.registerShop(
                  countryCode: countryCode,
                  phone: phoneController.text,
                  verificationCode: verificationController.text,
                  password: passwordController.text,
                  storeName: storeNameController.text,
                  address: fullAddress,
                  latitude: selectedLocation.latitude,
                  longitude: selectedLocation.longitude,
                  licenseFiles: licenseFiles,
                  serviceTypes: serviceTypes,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('商家注册已提交，请等待 Admin 审核')),
                );
              } on Object catch (exception) {
                setState(() => error =
                    exception.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: const Text('注册商家并加入地图'),
          ),
        ],
      ),
    );
  }

  void _addLicenseFile() {
    final file = licenseController.text.trim();
    if (file.isEmpty) {
      setState(() => error = '请填写许可证文件名或路径');
      return;
    }
    if (file == '1111') {
      setState(() {
        licenseFiles.add('mock-business-license.pdf');
        licenseController.clear();
        error = null;
      });
      return;
    }
    final lower = file.toLowerCase();
    final ok = lower.endsWith('.pdf') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
    if (!ok) {
      setState(() => error = '许可证文件支持 pdf、jpg、jpeg、png；测试可填写 1111');
      return;
    }
    setState(() {
      licenseFiles.add(file);
      licenseController.clear();
      error = null;
    });
  }

  void _collectLicenseInputIfPresent() {
    final file = licenseController.text.trim();
    if (file.isEmpty) {
      return;
    }
    if (file == '1111') {
      licenseFiles.add('mock-business-license.pdf');
      licenseController.clear();
      return;
    }
    final lower = file.toLowerCase();
    if (lower.endsWith('.pdf') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png')) {
      licenseFiles.add(file);
      licenseController.clear();
    }
  }

  void _toggleService(WashServiceType type, bool selected) {
    if (selected) {
      serviceTypes.add(type);
    } else {
      serviceTypes.remove(type);
    }
  }
}

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      UserHomePage(),
      UserReservationsPage(),
      OrdersPage(),
      ProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_car_wash_outlined),
            label: '洗车',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: '预约',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: '订单',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
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
              initialValue: selectedStoreId,
              decoration: const InputDecoration(
                labelText: '选择门店',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final store in widget.stores)
                  DropdownMenuItem(
                    value: store.id,
                    child: Text('${store.name} · ${store.address}'),
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
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<DateTime>(
                    initialValue: selectedDate,
                    decoration: const InputDecoration(
                      labelText: '预约日期',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final date in _dateOptions())
                        DropdownMenuItem(
                          value: date,
                          child: Text(formatDateOnly(date)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDate = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedTime,
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
                  ),
                ),
              ],
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
                title: Text(type.label),
                subtitle: Text(
                  type == WashServiceType.selfService
                      ? '自助洗车，更省水环保'
                      : '商家人工接待与精洗',
                ),
                contentPadding: EdgeInsets.zero,
              ),
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
              onPressed: () {
                try {
                  final reservation = appStore.createReservation(
                    storeId: selectedStoreId,
                    serviceType: selectedType,
                    userLocation: widget.userLocation,
                    arrivalTime: _arrivalDateTime(),
                    contactPhone: phoneController.text,
                    note: noteController.text,
                  );
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
  bool mapReady = false;
  String locationMessage = '正在获取定位...';

  @override
  void initState() {
    super.initState();
    // Defer heavy Google Map init so the first frame can render without ANR.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => mapReady = true);
      _loadLocation();
    });
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
          subtitle: '地图显示附近洗车店，列表按距离由近到远排序。',
        ),
        const SizedBox(height: 12),
        if (mapReady)
          CarWashMapView(
            key: mapKey,
            height: 220,
            cameraTarget: userLocation,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: !locating,
            onTap: (_) {},
          )
        else
          SizedBox(
            height: 220,
            child: Card(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      locationMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(locationMessage),
        if (locating) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          const MapSetupHintBanner(),
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
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8));
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<DateTime>(
                  value: selectedDate,
                  decoration: const InputDecoration(
                    labelText: '预约日期',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final date in _dateOptions())
                      DropdownMenuItem(
                        value: date,
                        child: Text(formatDateOnly(date)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedDate = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
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
                ),
              ),
            ],
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
              title: Text(type.label),
              subtitle: Text(
                type == WashServiceType.selfService
                    ? '每一次自助洗车节省约 60 升到 100 升的水，为环保贡献一份力量！'
                    : '由商家安排人工接待与精洗服务',
                style: type == WashServiceType.selfService
                    ? const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      )
                    : null,
              ),
            ),
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
            onPressed: () {
              try {
                final reservation = appStore.createReservation(
                  storeId: widget.store.id,
                  serviceType: selectedType,
                  userLocation: widget.userLocation,
                  arrivalTime: _arrivalDateTime(),
                  contactPhone: phoneController.text,
                  note: noteController.text,
                );
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
  const ScanPayPage({this.initialStore, super.key});

  final CarWashStore? initialStore;

  @override
  State<ScanPayPage> createState() => _ScanPayPageState();
}

class _ScanPayPageState extends State<ScanPayPage> {
  late String qrCode;
  late String selectedPackageId;
  bool useFreeWashThisOrder = false;
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
    qrCode = firstIdleDevice?.qrCode ?? 'CARWASH-1001';
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
    final selectedPackage =
        packages.firstWhere((washPackage) => washPackage.id == selectedPackageId);
    final canUseFreeWash = freeWashCredits > 0;
    final actualAmount = useFreeWashThisOrder && canUseFreeWash
        ? 0.0
        : selectedPackage.price;

    return Scaffold(
      appBar: AppBar(title: const Text('扫码支付')),
      body: AnimatedBuilder(
        animation: appStore,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionTitle(
                title: '扫码支付',
                subtitle: '选择设备与套餐，确认后进入收银台完成付款。',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: qrCode,
                decoration: const InputDecoration(
                  labelText: '设备二维码',
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
                        ? (value) =>
                            setState(() => useFreeWashThisOrder = value)
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
                      ? '处理中...'
                      : actualAmount <= 0
                          ? '确认并启动洗车'
                          : '前往付款 ¥${actualAmount.toStringAsFixed(0)}',
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
      setState(() => error = '请选择设备二维码');
      return;
    }
    if (selectedPackageId.trim().isEmpty) {
      setState(() => error = '请选择套餐');
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
      );
      if (!context.mounted) {
        return;
      }

      if (order.amount <= 0) {
        await appStore.markOrderPaid(
          order.id,
          transactionId: 'FREE-${order.id}',
          paymentMethod: '免费洗车',
        );
        await appStore.startOrder(order);
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已使用免费洗车 · 订单 ${order.id} 已启动')),
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
      final storeName = selectedStore?.name ?? '洗车门店';
      final packageName = selectedPackage.name;

      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            checkout: PaymentCheckoutArgs(
              orderId: order.id,
              storeName: storeName,
              packageName: packageName,
              amount: order.amount,
              usedFreeWash: order.usedFreeWashCredit,
              payerDisplayName: appStore.currentAccount?.displayName ?? '用户',
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
      );
      if (paid == true && context.mounted) {
        Navigator.of(context).pop();
      }
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
    const pages = [ShopStoresPage(), ShopReservationsPage(), ShopOrdersPage()];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: '店铺'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '预约'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: '订单'),
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
              subtitle: '用户付款后实时同步收款，可按店铺筛选查看。',
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
                    label: '已收款',
                    value:
                        '¥${appStore.receivedRevenueForCurrentShop(storeId: selectedStoreId == 'all' ? null : selectedStoreId).toStringAsFixed(0)}',
                    icon: Icons.payments,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    label: '待支付',
                    value:
                        '${appStore.pendingPaymentCountForCurrentShop(storeId: selectedStoreId == 'all' ? null : selectedStoreId)} 笔',
                    icon: Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MetricCard(
              label: '已完成订单',
              value: '$completed / ${orders.length}',
              icon: Icons.done_all,
            ),
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

  @override
  Widget build(BuildContext context) {
    const pages = [
      AdminOverviewPage(),
      AdminAccountsPage(),
      AdminStoresPage(),
      AdminReservationsPage(),
      AdminOrdersPage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: '总览'),
          NavigationDestination(icon: Icon(Icons.people), label: '账号'),
          NavigationDestination(icon: Icon(Icons.store), label: '店铺'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '预约'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: '订单'),
        ],
      ),
    );
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

class AdminAccountsPage extends StatelessWidget {
  const AdminAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = AppScope.of(context);
    return AnimatedBuilder(
      animation: appStore,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TopBar(title: '账号管理', subtitle: '管理用户账号和商家注册信息。'),
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
                account.licenseFiles.isNotEmpty)
              Text('许可证材料：${account.licenseFiles.join('，')}'),
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
      value: value,
      decoration: const InputDecoration(
        labelText: '店铺筛选',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('全部店铺')),
        for (final store in stores)
          DropdownMenuItem(value: store.id, child: Text(store.name)),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SectionTitle(title: title, subtitle: subtitle)),
        IconButton(
          onPressed: appStore.logout,
          icon: const Icon(Icons.logout),
          tooltip: '退出登录',
        ),
      ],
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
                  ),
                ),
                StatusPill(
                  text: reservation.status.label,
                  color: reservation.status.color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('用户：${user.displayName} ${reservation.contactPhone}'),
            Text('预约类型：${reservation.serviceType.label}'),
            Text('预约到店：${formatDateTime(reservation.arrivalTime)}'),
            Text(
              '预计 ${reservation.etaMinutes} 分钟到达，距离 ${reservation.distanceKm.toStringAsFixed(1)} km',
            ),
            if (reservation.note.isNotEmpty) Text('备注：${reservation.note}'),
            Text('提交时间：${formatTime(reservation.createdAt)}'),
            if (showActions) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final status in ReservationStatus.values)
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
            Text(
              store.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(store.address),
            Text('服务类型：${store.serviceSummary}'),
            Text(
              '累计收款 ¥${appStore.receivedRevenueForCurrentShop(storeId: store.id).toStringAsFixed(0)} · '
              '已付 ${appStore.paidOrderCountForCurrentShop(storeId: store.id)} 笔',
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
  final licenseController = TextEditingController();
  final licenseFiles = <String>[];
  final serviceTypes = <WashServiceType>{WashServiceType.selfService};
  String? error;

  @override
  void dispose() {
    storeNameController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    licenseController.dispose();
    super.dispose();
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
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: licenseController,
                  label: '文件名/路径，测试可填 1111',
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonal(
                  onPressed: _collectLicense,
                  child: const Text('添加'),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final file in licenseFiles)
                InputChip(
                  label: Text(file),
                  onDeleted: () => setState(() => licenseFiles.remove(file)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('服务类型', style: TextStyle(fontWeight: FontWeight.w700)),
          CheckboxListTile(
            value: serviceTypes.contains(WashServiceType.selfService),
            onChanged: (value) => setState(() {
              value == true
                  ? serviceTypes.add(WashServiceType.selfService)
                  : serviceTypes.remove(WashServiceType.selfService);
            }),
            title: const Text('自助洗车'),
          ),
          CheckboxListTile(
            value: serviceTypes.contains(WashServiceType.manual),
            onChanged: (value) => setState(() {
              value == true
                  ? serviceTypes.add(WashServiceType.manual)
                  : serviceTypes.remove(WashServiceType.manual);
            }),
            title: const Text('人工洗车'),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: () {
              try {
                _collectLicenseInputIfPresent();
                _validateRequired([
                  storeNameController.text,
                  addressController.text,
                  latController.text,
                  lngController.text,
                ]);
                if (serviceTypes.isEmpty) {
                  throw StateError('至少选择一种服务类型');
                }
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null || lng == null) {
                  throw StateError('经纬度格式不正确');
                }
                appStore.addStoreForCurrentShop(
                  storeName: storeNameController.text,
                  address: addressController.text,
                  latitude: lat,
                  longitude: lng,
                  licenseFiles: licenseFiles,
                  serviceTypes: serviceTypes,
                );
                Navigator.of(context).pop();
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

  void _collectLicense() {
    final file = licenseController.text.trim();
    if (file.isEmpty) {
      setState(() => error = '请填写文件名或 1111');
      return;
    }
    if (file == '1111') {
      setState(() {
        licenseFiles.add('mock-store-license.pdf');
        licenseController.clear();
        error = null;
      });
      return;
    }
    final lower = file.toLowerCase();
    if (!(lower.endsWith('.pdf') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png'))) {
      setState(() => error = '许可证文件支持 pdf、jpg、jpeg、png；测试可填写 1111');
      return;
    }
    setState(() {
      licenseFiles.add(file);
      licenseController.clear();
      error = null;
    });
  }

  void _collectLicenseInputIfPresent() {
    if (licenseController.text.trim().isNotEmpty) {
      _collectLicense();
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
                      order.usedFreeWashCredit ? '已核销免费洗车' : '已收款 ¥${order.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                    if (order.paymentMethod != null)
                      Text('支付方式：${order.paymentMethod}'),
                    if (order.paymentTransactionId != null)
                      Text('交易号：${order.paymentTransactionId}'),
                    Text('到账时间：${_formatPaidAt(order.paidAt!)}'),
                  ],
                ),
              ),
            ],
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
            if (order.status == OrderStatus.running) ...[
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
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15),
            const SizedBox(width: 4),
          ],
          Text(label),
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
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(description, textAlign: TextAlign.center),
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
      OrderStatus.paid => '2. 用户已付款，商家已收款，等待设备启动',
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
