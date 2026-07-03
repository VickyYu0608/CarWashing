class UserVehicle {
  UserVehicle({
    required this.id,
    required this.plate,
    required this.model,
    this.color = '',
  });

  final String id;
  String plate;
  String model;
  String color;

  String get displayLabel =>
      color.isEmpty ? '$model · $plate' : '$model（$color）· $plate';
}

class UserAddress {
  UserAddress({
    required this.id,
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String id;
  String label;
  String address;
  double? latitude;
  double? longitude;
}

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdAt,
    this.orderId,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime createdAt;
  final String? orderId;

  bool get isIncome => amount > 0;
}
