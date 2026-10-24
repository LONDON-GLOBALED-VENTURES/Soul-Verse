import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Login tokens, kept in the Android Keystore / iOS Keychain.
///
/// Older versions stored them in plain SharedPreferences; those are moved here on
/// first use so updating the app doesn't sign anyone out.
class AuthTokenStorage {
  AuthTokenStorage(this._secure, this._legacyPrefs);

  final FlutterSecureStorage _secure;
  final SharedPreferencesAsync _legacyPrefs;
  Future<void>? _migration;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  Future<String?> getAccessToken() => _read(_accessTokenKey);

  Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  // An unreadable keystore means signed out (sign in again), not a broken app.
  Future<String?> _read(String key) async {
    await _migrateOnce();
    try {
      return await _secure.read(key: key);
    } catch (e) {
      debugPrint('Could not read login token: $e');
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _migrateOnce();
    await _secure.write(key: _accessTokenKey, value: accessToken);
    await _secure.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _migrateOnce();
    await _secure.write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> clear() async {
    await _migrateOnce();
    await _secure.delete(key: _accessTokenKey);
    await _secure.delete(key: _refreshTokenKey);
  }

  Future<void> _migrateOnce() => _migration ??= _migrateLegacyTokens();

  Future<void> _migrateLegacyTokens() async {
    try {
      for (final key in [_accessTokenKey, _refreshTokenKey]) {
        final legacy = await _legacyPrefs.getString(key);
        if (legacy == null) continue;
        // A token already in secure storage is newer; never overwrite it.
        if (await _secure.read(key: key) == null) {
          await _secure.write(key: key, value: legacy);
        }
        await _legacyPrefs.remove(key);
      }
    } catch (e) {
      // Worst case the user signs in again; don't block every request on it.
      debugPrint('Could not migrate login tokens to secure storage: $e');
    }
  }
}

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage(
    const FlutterSecureStorage(),
    SharedPreferencesAsync(),
  );
});
