import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/date_format.dart';
import '../../verses/application/verses_providers.dart';
import '../../verses/data/models/daily_verse.dart';
import '../../verses/data/verses_api.dart';
import '../data/notification_scheduler.dart';
import '../data/reminder_settings.dart';

part 'reminder_service.g.dart';

/// Schedules [daysAhead] days of verse reminders with the actual verse text, then
/// [fallbackDays] more with generic text, so reminders keep coming for two months
/// even if the app isn't opened. Every launch reschedules from today.
///
/// All one-shot: a repeating daily notification would fire from tomorrow on both
/// platforms (they ignore its start date), duplicating the verse reminders.
class ReminderService {
  ReminderService(this._api, this._scheduler, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final VersesApi _api;
  final NotificationScheduler _scheduler;
  final DateTime Function() _now;

  static const daysAhead = 30;

  /// Keeps the total at 60, under iOS's limit of 64 pending notifications per app.
  static const fallbackDays = 30;
  static const fallbackBody =
      "Your daily verse is waiting for you - tap to read today's scripture and reflection.";

  Future<void> reschedule(ReminderSettings settings) async {
    await _scheduler.cancelAll();
    if (!settings.anyEnabled) return;

    final now = _now();
    final entries = await _fetchVerses(now);

    final setting = settings.daily;
    if (!setting.enabled) return;

    for (var day = 0; day < daysAhead + fallbackDays; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      final when = DateTime(
        date.year,
        date.month,
        date.day,
        setting.hour,
        setting.minute,
      );
      if (!when.isAfter(now)) continue;
      await _scheduler.schedule(
        id: day,
        when: when,
        title: 'Daily Verse',
        body: day < daysAhead
            ? _formatNotificationBody(entries[formatIsoDate(date)])
            : fallbackBody,
      );
    }
  }

  static String _formatNotificationBody(DailyVerse? entry) {
    if (entry == null) {
      return 'Take a moment with today\'s verse.';
    }
    final verse = entry.verse;
    return '“${verse.text}” — ${verse.reference}';
  }

  /// Keyed by date. Empty when offline: reminders still go out, with generic text.
  Future<Map<String, DailyVerse>> _fetchVerses(DateTime now) async {
    try {
      final range = await _api.getDailyRange(formatIsoDate(now), daysAhead);
      return {for (final entry in range) entry.date: entry};
    } catch (e) {
      debugPrint('Scheduling reminders without verse text: $e');
      return {};
    }
  }
}

@Riverpod(keepAlive: true)
ReminderService reminderService(Ref ref) => ReminderService(
  ref.watch(versesApiProvider),
  ref.watch(notificationSchedulerProvider),
);
