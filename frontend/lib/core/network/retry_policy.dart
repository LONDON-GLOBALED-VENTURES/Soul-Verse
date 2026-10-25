import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod's automatic retry for failed providers, minus pointless retries:
/// a 4xx answer (e.g. 404 "no verses yet") won't change by asking again, and
/// retrying would keep the screen loading for ~40s instead of showing it.
/// Network failures and 5xx still retry with Riverpod's default backoff.
Duration? appRetry(int retryCount, Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && status >= 400 && status < 500) return null;
  }
  return ProviderContainer.defaultRetry(retryCount, error);
}
