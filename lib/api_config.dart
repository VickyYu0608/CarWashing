import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// 后端地址：优先 `--dart-define=API_BASE_URL=...`，否则按平台自动选择。
///
/// - Android 模拟器：`10.0.2.2`（访问宿主机）
/// - 其它平台：`127.0.0.1`
String get kApiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  if (kIsWeb) {
    return 'http://127.0.0.1:8000';
  }
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}

String apiUrl(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final base = kApiBaseUrl.endsWith('/')
      ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1)
      : kApiBaseUrl;
  return '$base$normalizedPath';
}

String licenseFileUrl(String storedName) {
  final encoded = Uri.encodeComponent(storedName);
  return apiUrl('/uploads/licenses/$encoded');
}

bool isLicenseImageFile(String filename) {
  final lower = filename.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png');
}

bool isLicensePdfFile(String filename) {
  return filename.toLowerCase().endsWith('.pdf');
}

String apiConnectionHint() => '后端地址：$kApiBaseUrl';
