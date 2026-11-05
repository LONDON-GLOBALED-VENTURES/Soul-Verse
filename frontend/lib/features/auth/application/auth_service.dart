import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../favourites/data/favourites_repository.dart';
import '../data/auth_api.dart';
import '../data/auth_token_storage.dart';
import '../data/models/user.dart';

abstract class GoogleSignInService {
  Future<String?> getGoogleIdToken();
  Future<void> signOut();

  /// Signs out and revokes SoulVerse's access to the Google account.
  Future<void> disconnect();
}

const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: '469292499276-jcrki963pg3squtsbrs949h9h3erkhnq.apps.googleusercontent.com',
);

const _googleIOSClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: '469292499276-e3fv0ek19tp5jbo59cegksj1qou5u218.apps.googleusercontent.com',
);

class DefaultGoogleSignInService implements GoogleSignInService {
  DefaultGoogleSignInService([GoogleSignIn? googleSignIn])
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            clientId: Platform.isIOS ? _googleIOSClientId : null,
            serverClientId: _googleServerClientId,
            scopes: ['email', 'profile'],
          );

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

  @override
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // Revoking can fail offline; the account is already deleted, so just sign out.
      debugPrint('Google disconnect failed: $e');
      await signOut();
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
      await ref
          .read(authTokenStorageProvider)
          .saveTokens(
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

  /// Permanently deletes the account on the server, then signs out on this
  /// phone and removes that account's saved favourites. Throws if the server
  /// couldn't delete it, leaving the user signed in so they can try again.
  Future<void> deleteAccount() async {
    final user = state.value;
    await ref.read(authApiProvider).deleteAccount();

    await ref.read(googleSignInServiceProvider).disconnect();
    await ref.read(authTokenStorageProvider).clear();
    if (user != null) {
      await ref.read(favouritesRepositoryProvider).clear(userId: user.id);
    }
    state = const AsyncData(null);
  }

  Future<void> refreshUser() async {
    try {
      final api = ref.read(authApiProvider);
      final user = await api.getMe();
      state = AsyncData(user);
    } catch (_) {}
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).value?.id;
});
