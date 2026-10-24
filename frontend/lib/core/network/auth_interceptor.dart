import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_token_storage.dart';

/// Adds the access token to requests and, when one expires mid-session (401),
/// refreshes it once and retries the request.
///
/// Queued, so concurrent 401s wait for a single refresh instead of each refreshing.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._tokens, this._refreshDio, this._onSessionExpired);

  final AuthTokenStorage _tokens;

  /// Interceptor-free client for the refresh call and retries, so they can't loop back here.
  final Dio _refreshDio;
  final VoidCallback _onSessionExpired;

  static const _retriedFlag = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.getAccessToken();
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra[_retriedFlag] != true &&
        // Auth endpoints handle their own failures (see AuthNotifier._restoreSession).
        !request.path.startsWith('/auth/');
    if (!shouldRefresh) return handler.next(err);

    final usedToken = request.headers['Authorization'];
    var current = await _tokens.getAccessToken();

    // Another request may already have refreshed while this one waited in the queue.
    if (current == null || 'Bearer $current' == usedToken) {
      current = await _refreshAccessToken();
    }
    if (current == null) return handler.next(err);

    try {
      final retry = request
        ..headers['Authorization'] = 'Bearer $current'
        ..extra[_retriedFlag] = true;
      handler.resolve(await _refreshDio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Returns the new access token, or null if the session can't be renewed.
  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _tokens.getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final accessToken = response.data!['accessToken'] as String;
      await _tokens.saveAccessToken(accessToken);
      return accessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Only a rejected refresh token ends the session; being offline shouldn't sign anyone out.
      if (status == 401 || status == 403) {
        await _tokens.clear();
        _onSessionExpired();
      }
      debugPrint('Token refresh failed: ${status ?? e.type}');
      return null;
    }
  }
}
