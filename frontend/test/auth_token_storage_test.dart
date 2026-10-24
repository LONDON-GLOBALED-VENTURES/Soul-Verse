import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:soulverse/features/auth/data/auth_token_storage.dart';

class _BrokenSecureStorage extends FlutterSecureStorage {
  const _BrokenSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future.error(Exception('Failed to unwrap key'));
}

void main() {
  late SharedPreferencesAsync plainPrefs;
  const secure = FlutterSecureStorage();

  AuthTokenStorage storage() => AuthTokenStorage(secure, plainPrefs);

  void givenPlainPrefs(Map<String, Object> data) {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(data);
    plainPrefs = SharedPreferencesAsync();
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    givenPlainPrefs({});
  });

  test('tokens are saved in secure storage, not plain preferences', () async {
    givenPlainPrefs({});
    await storage().saveTokens(accessToken: 'a1', refreshToken: 'r1');

    expect(await secure.read(key: 'auth_access_token'), 'a1');
    expect(await secure.read(key: 'auth_refresh_token'), 'r1');
    expect(await plainPrefs.getKeys(), isEmpty);
  });

  test(
    'an existing signed-in user is moved over and stays signed in',
    () async {
      givenPlainPrefs({
        'auth_access_token': 'old-access',
        'auth_refresh_token': 'old-refresh',
        'favourites_guest': '{"version":1,"items":[]}',
      });

      final tokens = storage();
      expect(await tokens.getAccessToken(), 'old-access');
      expect(await tokens.getRefreshToken(), 'old-refresh');

      // Plain copies are gone; unrelated preferences are untouched.
      expect(await plainPrefs.getString('auth_access_token'), isNull);
      expect(await plainPrefs.getString('auth_refresh_token'), isNull);
      expect(await plainPrefs.getString('favourites_guest'), isNotNull);
    },
  );

  test(
    'a newer token in secure storage is never overwritten by an old one',
    () async {
      FlutterSecureStorage.setMockInitialValues({'auth_access_token': 'newer'});
      givenPlainPrefs({'auth_access_token': 'stale'});

      expect(await storage().getAccessToken(), 'newer');
      expect(await plainPrefs.getString('auth_access_token'), isNull);
    },
  );

  test('signing out clears both stores', () async {
    givenPlainPrefs({'auth_refresh_token': 'old-refresh'});
    final tokens = storage();
    await tokens.saveAccessToken('a1');

    await tokens.clear();

    expect(await tokens.getAccessToken(), isNull);
    expect(await tokens.getRefreshToken(), isNull);
    expect(await plainPrefs.getString('auth_refresh_token'), isNull);
  });

  test(
    'an unreadable keystore counts as signed out instead of failing',
    () async {
      final tokens = AuthTokenStorage(const _BrokenSecureStorage(), plainPrefs);
      expect(await tokens.getAccessToken(), isNull);
      expect(await tokens.getRefreshToken(), isNull);
    },
  );

  test('signed-out users have no tokens', () async {
    givenPlainPrefs({});
    expect(await storage().getAccessToken(), isNull);
    expect(await storage().getRefreshToken(), isNull);
  });
}
