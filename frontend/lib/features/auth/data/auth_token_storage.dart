import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStorage {
  AuthTokenStorage(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  Future<String?> getAccessToken() => _prefs.getString(_accessTokenKey);

  Future<String?> getRefreshToken() => _prefs.getString(_refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _prefs.setString(_accessTokenKey, accessToken);
  }

  Future<void> clear() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
}

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage(SharedPreferencesAsync());
});
