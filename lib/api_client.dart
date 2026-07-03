import 'dart:convert';

import 'package:car_washing_app/api_config.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiConnectionException implements Exception {
  ApiConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  static String? accessToken;
  static bool useBackend = true;

  static Map<String, String> _headers({bool jsonBody = false}) {
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  static String _readError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] is String) {
            return first['msg'] as String;
          }
        }
      }
    } on Object {
      // ignore
    }
    return '请求失败（${response.statusCode}）';
  }

  static Future<T> _request<T>(
    Future<http.Response> Function() call,
    T Function(http.Response response) onSuccess,
  ) async {
    try {
      final response = await call().timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return onSuccess(response);
      }
      throw ApiException(_readError(response), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      throw ApiConnectionException(
        '无法连接后端（$kApiBaseUrl），请确认服务已启动。$error',
      );
    }
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    return _request(
      () => http.post(
        Uri.parse(apiUrl('/api/auth/login')),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      ),
      (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        accessToken = json['access_token'] as String?;
        return json;
      },
    );
  }

  static Future<Map<String, dynamic>> getMe() => _request(
        () => http.get(Uri.parse(apiUrl('/api/auth/me')), headers: _headers()),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) =>
      _request(
        () => http.patch(
          Uri.parse(apiUrl('/api/auth/me')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> registerUser({
    required String countryCode,
    required String phone,
    required String verificationCode,
    required String password,
    required String displayName,
    String referralCode = '',
  }) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/auth/register/user')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({
            'country_code': countryCode,
            'phone': phone.trim(),
            'verification_code': verificationCode.trim(),
            'password': password,
            'display_name': displayName.trim(),
            'referral_code': referralCode.trim(),
          }),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> registerShop({
    required String countryCode,
    required String phone,
    required String verificationCode,
    required String password,
    required String storeName,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> licenseFiles,
    required List<String> serviceTypes,
  }) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/auth/register/shop')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({
            'country_code': countryCode,
            'phone': phone.trim(),
            'verification_code': verificationCode.trim(),
            'password': password,
            'store_name': storeName.trim(),
            'address': address.trim(),
            'latitude': latitude,
            'longitude': longitude,
            'license_files': licenseFiles,
            'service_types': serviceTypes,
          }),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> redeemReferral(String code) => _request(
        () => http.post(
          Uri.parse(apiUrl('/api/auth/referral/redeem')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({'code': code.trim()}),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<List<Map<String, dynamic>>> fetchAccounts() => _request(
        () => http.get(
          Uri.parse(apiUrl('/api/auth/accounts')),
          headers: _headers(),
        ),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<Map<String, dynamic>> updateApproval({
    required String accountId,
    required String approvalStatus,
    String adminReply = '',
  }) =>
      _request(
        () => http.patch(
          Uri.parse(apiUrl('/api/auth/accounts/$accountId/approval')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({
            'approval_status': approvalStatus,
            'admin_reply': adminReply,
          }),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<List<Map<String, dynamic>>> fetchStores() => _request(
        () => http.get(Uri.parse(apiUrl('/api/stores')), headers: _headers()),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<List<Map<String, dynamic>>> fetchMyStores() => _request(
        () => http.get(
          Uri.parse(apiUrl('/api/stores/mine')),
          headers: _headers(),
        ),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<List<Map<String, dynamic>>> fetchOrders() => _request(
        () => http.get(Uri.parse(apiUrl('/api/orders')), headers: _headers()),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/orders')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> updateOrder(
    String orderId,
    Map<String, dynamic> body,
  ) =>
      _request(
        () => http.patch(
          Uri.parse(apiUrl('/api/orders/$orderId')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<List<Map<String, dynamic>>> fetchReservations() => _request(
        () => http.get(
          Uri.parse(apiUrl('/api/reservations')),
          headers: _headers(),
        ),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<Map<String, dynamic>> createReservation(
    Map<String, dynamic> body,
  ) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/reservations')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> updateReservation(
    String reservationId,
    Map<String, dynamic> body,
  ) =>
      _request(
        () => http.patch(
          Uri.parse(apiUrl('/api/reservations/$reservationId')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> fetchWallet() => _request(
        () => http.get(Uri.parse(apiUrl('/api/wallet')), headers: _headers()),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> withdrawWallet(double amount) => _request(
        () => http.post(
          Uri.parse(apiUrl('/api/wallet/withdraw')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({'amount': amount}),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<List<Map<String, dynamic>>> fetchVehicles() => _request(
        () => http.get(Uri.parse(apiUrl('/api/vehicles')), headers: _headers()),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<Map<String, dynamic>> createVehicle(
    Map<String, dynamic> body,
  ) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/vehicles')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<void> deleteVehicle(String vehicleId) => _request(
        () => http.delete(
          Uri.parse(apiUrl('/api/vehicles/$vehicleId')),
          headers: _headers(),
        ),
        (_) {},
      );

  static Future<List<Map<String, dynamic>>> fetchAddresses() => _request(
        () => http.get(
          Uri.parse(apiUrl('/api/addresses')),
          headers: _headers(),
        ),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<Map<String, dynamic>> createAddress(
    Map<String, dynamic> body,
  ) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/addresses')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<void> deleteAddress(String addressId) => _request(
        () => http.delete(
          Uri.parse(apiUrl('/api/addresses/$addressId')),
          headers: _headers(),
        ),
        (_) {},
      );

  static Future<List<Map<String, dynamic>>> fetchReviews() => _request(
        () => http.get(Uri.parse(apiUrl('/api/reviews')), headers: _headers()),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl('/health')))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } on Object {
      return false;
    }
  }

  static Future<Map<String, dynamic>> sendSmsCode({
    required String countryCode,
    required String phone,
    String purpose = 'register',
  }) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/auth/sms/send')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({
            'country_code': countryCode,
            'phone': phone.trim(),
            'purpose': purpose,
          }),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<List<Map<String, dynamic>>> fetchBundles() => _request(
        () => http.get(Uri.parse(apiUrl('/api/bundles')), headers: _headers()),
        (r) => (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>(),
      );

  static Future<Map<String, dynamic>> purchaseBundle(String planId) => _request(
        () => http.post(
          Uri.parse(apiUrl('/api/bundles/purchase')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({'plan_id': planId}),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> fetchAdminPending() => _request(
        () => http.get(
          Uri.parse(apiUrl('/api/admin/pending')),
          headers: _headers(),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> updateStoreApproval({
    required String storeId,
    required String approvalStatus,
    String adminReply = '',
  }) =>
      _request(
        () => http.patch(
          Uri.parse(apiUrl('/api/admin/stores/$storeId/approval')),
          headers: _headers(jsonBody: true),
          body: jsonEncode({
            'approval_status': approvalStatus,
            'admin_reply': adminReply,
          }),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> createStore(Map<String, dynamic> body) =>
      _request(
        () => http.post(
          Uri.parse(apiUrl('/api/stores')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> updatePackage(
    String storeId,
    String packageId,
    Map<String, dynamic> body,
  ) =>
      _request(
        () => http.patch(
          Uri.parse(apiUrl('/api/stores/$storeId/packages/$packageId')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );

  static Future<Map<String, dynamic>> updateBundlePlan(
    String planId,
    Map<String, dynamic> body,
  ) =>
      _request(
        () => http.patch(
          Uri.parse(apiUrl('/api/bundles/$planId')),
          headers: _headers(jsonBody: true),
          body: jsonEncode(body),
        ),
        (r) => jsonDecode(r.body) as Map<String, dynamic>,
      );
}
