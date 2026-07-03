import 'dart:convert';

import 'package:car_washing_app/maps_api_key.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeocodingException implements Exception {
  GeocodingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeocodeResult {
  const GeocodeResult({
    required this.position,
    this.formattedAddress,
  });

  final LatLng position;
  final String? formattedAddress;
}

class GeocodingService {
  static Future<GeocodeResult> geocode(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      throw GeocodingException('地址不能为空');
    }

    final apiKey = await MapsApiKey.resolve();
    if (apiKey.isEmpty) {
      throw GeocodingException(
        '未配置 Google Maps API Key，请在 android/secrets.properties 填写 google.maps.api.key',
      );
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': query,
        'key': apiKey,
        'region': 'hk',
        'language': 'zh-HK',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeocodingException('地理编码请求失败（${response.statusCode}）');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      final message = switch (status) {
        'ZERO_RESULTS' => '未找到该地址，请检查详细地址或区域选择',
        'REQUEST_DENIED' =>
          'Geocoding API 未启用或 API Key 无效，请在 Google Cloud 启用 Geocoding API',
        'OVER_QUERY_LIMIT' => '地理编码请求过多，请稍后再试',
        _ => '地理编码失败：$status',
      };
      throw GeocodingException(message);
    }

    final results = body['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      throw GeocodingException('未找到该地址对应坐标');
    }

    final first = results.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      throw GeocodingException('无法解析地址坐标');
    }

    return GeocodeResult(
      position: LatLng(lat, lng),
      formattedAddress: first['formatted_address'] as String?,
    );
  }
}
