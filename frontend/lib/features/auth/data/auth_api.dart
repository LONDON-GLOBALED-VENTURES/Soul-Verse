import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'models/user.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> signInWithGoogle(String idToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'idToken': idToken},
    );
    return AuthSession.fromJson(response.data!);
  }

  Future<String> refreshToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return response.data!['accessToken'] as String;
  }

  Future<User> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return User.fromJson(response.data!['user'] as Map<String, dynamic>);
  }

  /// Permanently deletes the signed-in user's account and everything they shared.
  Future<void> deleteAccount() async {
    await _dio.delete<void>('/auth/me');
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioClientProvider));
});
