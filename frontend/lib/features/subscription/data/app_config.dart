import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Settings the backend gives the app at start-up (GET /api/config).
@immutable
class AppConfig {
  const AppConfig({required this.billingEnabled});

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      AppConfig(billingEnabled: json['billingEnabled'] as bool? ?? true);

  /// Used when the config can't be loaded: billing stays on, so Premium
  /// features stay locked rather than unlocking by accident.
  static const defaults = AppConfig(billingEnabled: true);

  /// False on a QA/staging backend: every Premium feature is unlocked.
  final bool billingEnabled;
}

class AppConfigApi {
  AppConfigApi(this._dio);

  final Dio _dio;

  Future<AppConfig> fetch() async {
    final response = await _dio.get<Map<String, dynamic>>('/config');
    return AppConfig.fromJson(response.data!);
  }
}

final appConfigApiProvider = Provider<AppConfigApi>(
  (ref) => AppConfigApi(ref.watch(dioClientProvider)),
);

/// Loaded once per launch.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  try {
    return await ref.watch(appConfigApiProvider).fetch();
  } catch (e) {
    debugPrint('Couldn\'t load app config, keeping billing on: $e');
    return AppConfig.defaults;
  }
});
