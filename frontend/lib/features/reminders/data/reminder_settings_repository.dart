import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_settings.dart';

part 'reminder_settings_repository.g.dart';

class ReminderSettingsRepository {
  ReminderSettingsRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'reminder_settings';

  Future<ReminderSettings> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return ReminderSettings.defaults;
    try {
      return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Resetting unreadable reminder settings: $e');
      return ReminderSettings.defaults;
    }
  }

  Future<void> save(ReminderSettings settings) =>
      _prefs.setString(_key, jsonEncode(settings.toJson()));
}

@Riverpod(keepAlive: true)
ReminderSettingsRepository reminderSettingsRepository(Ref ref) =>
    ReminderSettingsRepository(SharedPreferencesAsync());
