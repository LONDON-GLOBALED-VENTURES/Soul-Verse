import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/verse_style.dart';

part 'verse_style_store.g.dart';

/// Remembers the last style used on the share screen, so the next verse
/// starts with the same look.
class VerseStyleStore {
  VerseStyleStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'last_verse_style';

  Future<VerseStyle> load() async {
    try {
      final raw = await _prefs.getString(_key);
      if (raw == null) return VerseStyle.standard;
      final style = VerseStyle.fromJson(
        jsonDecode(raw) as Map<String, Object?>,
      );
      // The phone may have cleared a picked photo since; fall back to the template.
      final background = style.customBackground;
      if (background is PhotoBackground &&
          !File(background.path).existsSync()) {
        return style.copyWith(customBackground: null);
      }
      return style;
    } catch (e) {
      // A damaged copy shouldn't block the screen; start from the default look.
      debugPrint('Discarding unreadable verse style: $e');
      return VerseStyle.standard;
    }
  }

  Future<void> save(VerseStyle style) =>
      _prefs.setString(_key, jsonEncode(style.forNextTime().toJson()));
}

@Riverpod(keepAlive: true)
VerseStyleStore verseStyleStore(Ref ref) =>
    VerseStyleStore(SharedPreferencesAsync());
