import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/theme/app_colors.dart';

part 'notification_scheduler.g.dart';

/// Thin wrapper over flutter_local_notifications so reminder logic can be tested without plugins.
class NotificationScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialized;

  // Big-text style lets long verses expand in the Android notification shade.
  static NotificationDetails _detailsFor(String body, [String? title]) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'verse_reminders_v2',
          'Daily Verse Reminders',
          channelDescription: 'Daily verse reminder',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          color: AppColors.accent,
          icon: 'ic_notification',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'SoulVerse',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      );

  Future<void> _ensureInitialized() => _initialized ??= _initialize();

  static const _sixMonths = Duration(days: 182);

  /// The zone reminders are scheduled in: the device's zone by name, or when that
  /// name is unknown to the timezone database, a zone whose UTC offset matches the
  /// device both now and six months ahead (so summer-time changes line up too).
  /// UTC only as a last resort.
  @visibleForTesting
  static tz.Location resolveLocation(
    String? identifier, {
    required int nowMillis,
    required Duration offsetNow,
    required Duration offsetInSixMonths,
  }) {
    if (identifier != null) {
      try {
        return tz.getLocation(identifier);
      } on tz.LocationNotFoundException {
        // Fall through to matching by offset.
      }
    }
    final later = nowMillis + _sixMonths.inMilliseconds;
    bool offsetsMatch(tz.Location location) =>
        location.timeZone(nowMillis).offset == offsetNow &&
        location.timeZone(later).offset == offsetInSixMonths;
    return tz.timeZoneDatabase.locations.values
            .where(offsetsMatch)
            .firstOrNull ??
        tz.UTC;
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    String? identifier;
    try {
      identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (e) {
      debugPrint('Could not read device timezone: $e');
    }
    final now = DateTime.now();
    tz.setLocalLocation(
      resolveLocation(
        identifier,
        nowMillis: now.millisecondsSinceEpoch,
        offsetNow: now.timeZoneOffset,
        offsetInSixMonths: now.add(_sixMonths).timeZoneOffset,
      ),
    );
    debugPrint('Reminder timezone: ${tz.local.name} (device: $identifier)');
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Permission is requested explicitly when the user turns a reminder on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'verse_reminders_v2',
        'Daily Verse Reminders',
        description: 'Daily verse reminder',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Shows the system permission prompt (Android 13+ / iOS). Returns whether it was granted.
  Future<bool> requestPermission() async {
    try {
      await _ensureInitialized();
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        // If already granted / enabled at OS level, return true immediately.
        final areEnabled = await android?.areNotificationsEnabled();
        if (areEnabled == true) return true;

        final requested = await android?.requestNotificationsPermission();
        if (requested == true) return true;

        final recheck = await android?.areNotificationsEnabled();
        if (recheck == true) return true;

        // On Android versions prior to 13 (API < 33), runtime permission prompt is not supported.
        // If areNotificationsEnabled returned null, default to true.
        if (recheck == null) return true;

        return false;
      }
      if (Platform.isIOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return true;
    }
    return true;
  }

  /// Schedules a one-time notification at [when], a local wall-clock time.
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime(
        tz.local,
        when.year,
        when.month,
        when.day,
        when.hour,
        when.minute,
      ),
      notificationDetails: _detailsFor(body, title),
      androidScheduleMode: scheduleModeFor(await _canScheduleExact()),
      title: title,
      body: body,
    );
  }

  /// Exact timing keeps reminders on time on phones with aggressive battery saving.
  /// Android 14+ denies exact alarms by default (the user grants SCHEDULE_EXACT_ALARM
  /// in settings), and scheduling an exact alarm without it throws, so fall back to
  /// inexact delivery, which may arrive a few minutes late.
  @visibleForTesting
  static AndroidScheduleMode scheduleModeFor(bool? canScheduleExact) =>
      canScheduleExact == false
      ? AndroidScheduleMode.inexactAllowWhileIdle
      : AndroidScheduleMode.exactAllowWhileIdle;

  /// Null off Android or below Android 12, where exact alarms need no permission.
  Future<bool?> _canScheduleExact() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.canScheduleExactNotifications();
    } catch (e) {
      debugPrint('Could not check exact alarm permission: $e');
      return false;
    }
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }
}

@Riverpod(keepAlive: true)
NotificationScheduler notificationScheduler(Ref ref) => NotificationScheduler();
