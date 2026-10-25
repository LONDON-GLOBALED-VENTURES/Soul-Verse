import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_service.dart';
import '../../features/auth/data/auth_token_storage.dart';
import 'auth_interceptor.dart';

part 'dio_client.g.dart';

const _configuredBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.example.com/api',
);

/// Endpoint paths are relative to `…/api` (e.g. '/prayers'), so a base URL
/// given as just the server address (`https://host`) gets `/api` added.
@visibleForTesting
String normalizeApiBaseUrl(String url) {
  final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
  return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
}

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: normalizeApiBaseUrl(_configuredBaseUrl),
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {'Content-Type': 'application/json'},
);

@riverpod
Dio dioClient(Ref ref) {
  final dio = Dio(_baseOptions());

  dio.interceptors.add(
    AuthInterceptor(
      ref.read(authTokenStorageProvider),
      Dio(_baseOptions()),
      // Re-reads the (now cleared) tokens, so the app shows the user as signed out.
      () => ref.invalidate(authProvider),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
}
