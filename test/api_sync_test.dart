import 'package:car_washing_app/app_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppSync parses store json', () {
    final store = AppSync.storeFromJson({
      'id': 'store-1',
      'owner_account_id': 'shop-1',
      'name': '测试店',
      'address': '测试地址',
      'latitude': 22.28,
      'longitude': 114.15,
      'rating': 4.5,
      'tags': ['24小时'],
      'service_types': ['selfService', 'manual'],
      'devices': [],
      'packages': [
        {
          'id': 'pkg-1',
          'name': '标准洗',
          'minutes': 20,
          'price': 28,
          'description': '测试',
        },
      ],
    });
    expect(store.name, '测试店');
    expect(store.packages.length, 1);
  });

  test('AppSync parses reservation json', () {
    final reservation = AppSync.reservationFromJson({
      'id': 'res-1',
      'user_account_id': 'user-1',
      'store_id': 'store-1',
      'service_type': 'selfService',
      'user_latitude': 22.28,
      'user_longitude': 114.15,
      'distance_km': 1.2,
      'eta_minutes': 8,
      'arrival_time': '2026-07-03T12:00:00',
      'contact_phone': '13800000000',
      'note': '',
      'created_at': '2026-07-03T10:00:00',
      'status': 'pending',
    });
    expect(reservation.storeId, 'store-1');
    expect(reservation.etaMinutes, 8);
  });
}
