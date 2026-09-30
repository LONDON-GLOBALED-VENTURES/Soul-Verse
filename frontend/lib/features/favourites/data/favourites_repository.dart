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

  static const _key = 'favourites';

  // Bump when the stored shape changes, and migrate older versions in [load].
  static const _schemaVersion = 1;

  Future<List<FavouriteVerse>> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (json['items'] as List)
          .map((e) => FavouriteVerse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Unreadable data shouldn't crash the app; start fresh rather than block the screen.
      debugPrint('Discarding unreadable favourites: $e');
      return [];
    }
  }

  Future<void> save(List<FavouriteVerse> favourites) => _prefs.setString(
    _key,
    jsonEncode({
      'version': _schemaVersion,
      'items': favourites.map((f) => f.toJson()).toList(),
    }),
  );
}

@Riverpod(keepAlive: true)
FavouritesRepository favouritesRepository(Ref ref) =>
    FavouritesRepository(SharedPreferencesAsync());
