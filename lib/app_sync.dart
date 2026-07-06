import 'package:car_washing_app/main.dart';
import 'package:car_washing_app/models/service_order.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 将后端 JSON 同步到 AppStore
class AppSync {
  static List<CarWashStore> parseStores(List<Map<String, dynamic>> items) {
    final parsed = <CarWashStore>[];
    for (final json in items) {
      try {
        parsed.add(storeFromJson(json));
      } on Object {
        // Skip malformed store records instead of failing the whole sync.
      }
    }
    return parsed;
  }

  static List<WashOrder> parseOrders(List<Map<String, dynamic>> items) {
    final parsed = <WashOrder>[];
    for (final json in items) {
      try {
        parsed.add(orderFromJson(json));
      } on Object {
        // Skip malformed order records.
      }
    }
    return parsed;
  }

  static List<Reservation> parseReservations(List<Map<String, dynamic>> items) {
    final parsed = <Reservation>[];
    for (final json in items) {
      try {
        parsed.add(reservationFromJson(json));
      } on Object {
        // Skip malformed reservation records.
      }
    }
    return parsed;
  }

  static List<UserVehicle> parseVehicles(List<Map<String, dynamic>> items) {
    final parsed = <UserVehicle>[];
    for (final json in items) {
      try {
        parsed.add(vehicleFromJson(json));
      } on Object {
        // Skip malformed vehicle records.
      }
    }
    return parsed;
  }

  static List<UserAddress> parseAddresses(List<Map<String, dynamic>> items) {
    final parsed = <UserAddress>[];
    for (final json in items) {
      try {
        parsed.add(addressFromJson(json));
      } on Object {
        // Skip malformed address records.
      }
    }
    return parsed;
  }

  static List<WalletTransaction> parseWalletTransactions(
    List<Map<String, dynamic>> items,
  ) {
    final parsed = <WalletTransaction>[];
    for (final json in items) {
      try {
        parsed.add(walletTxnFromJson(json));
      } on Object {
        // Skip malformed wallet records.
      }
    }
    return parsed;
  }

  static CarWashStore storeFromJson(Map<String, dynamic> json) {
    final serviceTypes = <WashServiceType>{};
    for (final item in json['service_types'] as List<dynamic>? ?? []) {
      if (item == 'manual') {
        serviceTypes.add(WashServiceType.manual);
      } else {
        serviceTypes.add(WashServiceType.selfService);
      }
    }
    return CarWashStore(
      id: json['id'] as String,
      ownerAccountId: json['owner_account_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      serviceTypes: serviceTypes.isEmpty
          ? {WashServiceType.selfService}
          : serviceTypes,
      devices: [
        for (final device in json['devices'] as List<dynamic>? ?? [])
          WashDevice(
            id: device['id'] as String,
            qrCode: device['qr_code'] as String,
            bayName: device['bay_name'] as String,
            status: _deviceStatus(device['status'] as String?),
            lastHeartbeat: DateTime.parse(device['last_heartbeat'] as String),
            totalUseSeconds: device['total_use_seconds'] as int? ?? 0,
            useCount: device['use_count'] as int? ?? 0,
            faultCount: device['fault_count'] as int? ?? 0,
          ),
      ],
      packages: [
        for (final pkg in json['packages'] as List<dynamic>? ?? [])
          ServicePackage(
            id: pkg['id'] as String,
            name: pkg['name'] as String,
            minutes: pkg['minutes'] as int,
            price: (pkg['price'] as num).toDouble(),
            description: pkg['description'] as String? ?? '',
          ),
      ],
      approvalStatus: _approvalStatus(json['approval_status'] as String?),
      adminReply: json['admin_reply'] as String? ?? '',
    );
  }

  static ApprovalStatus _approvalStatus(String? value) {
    switch (value) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.approved;
    }
  }

  static WashOrder orderFromJson(Map<String, dynamic> json) {
    return WashOrder(
      id: json['id'] as String,
      userAccountId: json['user_account_id'] as String,
      storeId: json['store_id'] as String,
      deviceId: json['device_id'] as String,
      packageId: json['package_id'] as String,
      status: _orderStatus(json['status'] as String?),
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
      remainingSeconds: json['remaining_seconds'] as int? ?? 0,
      failureReason: json['failure_reason'] as String?,
      usedFreeWashCredit: json['used_free_wash_credit'] as bool? ?? false,
    );
  }

  static Reservation reservationFromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      userAccountId: json['user_account_id'] as String,
      storeId: json['store_id'] as String,
      serviceType: json['service_type'] == 'manual'
          ? WashServiceType.manual
          : WashServiceType.selfService,
      userLocation: LatLng(
        (json['user_latitude'] as num).toDouble(),
        (json['user_longitude'] as num).toDouble(),
      ),
      distanceKm: (json['distance_km'] as num).toDouble(),
      etaMinutes: json['eta_minutes'] as int,
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      contactPhone: json['contact_phone'] as String,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      status: _reservationStatus(json['status'] as String?),
    );
  }

  static UserVehicle vehicleFromJson(Map<String, dynamic> json) {
    return UserVehicle(
      id: json['id'] as String,
      plate: json['plate'] as String,
      model: json['model'] as String,
      color: json['color'] as String? ?? '',
    );
  }

  static UserAddress addressFromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  static WalletTransaction walletTxnFromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      orderId: json['order_id'] as String?,
    );
  }

  static DeviceStatus _deviceStatus(String? value) {
    switch (value) {
      case 'busy':
        return DeviceStatus.busy;
      case 'offline':
        return DeviceStatus.offline;
      case 'faulted':
        return DeviceStatus.faulted;
      default:
        return DeviceStatus.idle;
    }
  }

  static OrderStatus _orderStatus(String? value) {
    switch (value) {
      case 'paid':
        return OrderStatus.paid;
      case 'starting':
        return OrderStatus.starting;
      case 'running':
        return OrderStatus.running;
      case 'completed':
        return OrderStatus.completed;
      case 'failed':
        return OrderStatus.failed;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.created;
    }
  }

  static ReservationStatus _reservationStatus(String? value) {
    switch (value) {
      case 'arrived':
        return ReservationStatus.arrived;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.pending;
    }
  }
}
