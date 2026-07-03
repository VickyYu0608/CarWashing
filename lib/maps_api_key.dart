import 'package:flutter/services.dart';

class MapsApiKey {
  static const MethodChannel _channel =
      MethodChannel('com.example.car_washing_app/maps');

  static String? _cached;

  static Future<String> resolve() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }

    const fromEnv = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (fromEnv.isNotEmpty) {
      _cached = fromEnv;
      return fromEnv;
    }

    try {
      final key = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      _cached = key?.trim() ?? '';
      return _cached!;
    } on Object {
      _cached = '';
      return '';
    }
  }
}
