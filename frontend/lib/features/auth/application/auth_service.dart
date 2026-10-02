import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/auth_api.dart';
import '../data/auth_token_storage.dart';
import '../data/models/user.dart';

abstract class GoogleSignInService {
  Future<String?> getGoogleIdToken();
  Future<void> signOut();
}

class DefaultGoogleSignInService implements GoogleSignInService {
  DefaultGoogleSignInService([GoogleSignIn? googleSignIn])
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> getGoogleIdToken() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
  }
}

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return DefaultGoogleSignInService();
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return _restoreSession();
  }

  Future<User?> _restoreSession() async {
    final tokenStorage = ref.read(authTokenStorageProvider);
    final accessToken = await tokenStorage.getAccessToken();
    if (accessToken == null) return null;

    final api = ref.read(authApiProvider);
    try {
      return await api.getMe();
    } catch (_) {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final newAccessToken = await api.refreshToken(refreshToken);
          await tokenStorage.saveAccessToken(newAccessToken);
          return await api.getMe();
        } catch (_) {
          await tokenStorage.clear();
        }
      } else {
        await tokenStorage.clear();
      }
      return null;
    }
  }

  Future<bool> signInWithGoogle() async {
    final previousUser = state.value;
    state = const AsyncLoading();
    try {
      final googleService = ref.read(googleSignInServiceProvider);
      final idToken = await googleService.getGoogleIdToken();
      if (idToken == null) {
        state = AsyncData(previousUser);
        return false;
      }

      final api = ref.read(authApiProvider);
      final session = await api.signInWithGoogle(idToken);
      await ref.read(authTokenStorageProvider).saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      state = AsyncData(session.user);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(googleSignInServiceProvider).signOut();
      await ref.read(authTokenStorageProvider).clear();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
