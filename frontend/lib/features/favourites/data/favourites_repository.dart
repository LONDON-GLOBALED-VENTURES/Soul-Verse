import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favourite_verse.dart';

part 'favourites_repository.g.dart';

/// Stores favourites on the device. Swap for a synced implementation once accounts exist.
class FavouritesRepository {
  FavouritesRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _legacyKey = 'favourites';
  static const _baseKey = 'favourites';

  // Bump when the stored shape changes, and migrate older versions in [load].
  static const _schemaVersion = 1;

  String _storageKey(String? userId) =>
      userId != null && userId.trim().isNotEmpty
      ? '${_baseKey}_${userId.trim()}'
      : '${_baseKey}_guest';

  Future<List<FavouriteVerse>> load({String? userId}) async {
    final key = _storageKey(userId);
    var raw = await _prefs.getString(key);

    // Legacy migration: if legacy 'favourites' exists and guest key is empty,
    // migrate legacy data to guest so existing users never lose their saved verses.
    if (raw == null && (userId == null || userId.trim().isEmpty)) {
      final legacyRaw = await _prefs.getString(_legacyKey);
      if (legacyRaw != null) {
        raw = legacyRaw;
        await _prefs.setString(key, legacyRaw);
        await _prefs.remove(_legacyKey);
      }
    }

    if (raw == null) return [];
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (json['items'] as List)
          .map((e) => FavouriteVerse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Unreadable data shouldn't crash the app; start fresh rather than block the screen.
      debugPrint('Discarding unreadable favourites for $key: $e');
      return [];
    }
  }

  Future<void> save(List<FavouriteVerse> favourites, {String? userId}) =>
      _prefs.setString(
        _storageKey(userId),
        jsonEncode({
          'version': _schemaVersion,
          'items': favourites.map((f) => f.toJson()).toList(),
        }),
      );

  /// Removes the favourites saved on this phone for [userId] (e.g. after the
  /// account is deleted).
  Future<void> clear({String? userId}) => _prefs.remove(_storageKey(userId));
}

@Riverpod(keepAlive: true)
FavouritesRepository favouritesRepository(Ref ref) =>
    FavouritesRepository(SharedPreferencesAsync());
