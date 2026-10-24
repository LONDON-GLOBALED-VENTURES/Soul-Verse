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

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      final id = zone.identifier;
      debugPrint('Device timezone identifier: $id');
      try {
        tz.setLocalLocation(tz.getLocation(id));
        debugPrint('Timezone set to: ${tz.local.name}');
      } catch (e) {
        debugPrint(
          'tz.getLocation("$id") failed: $e — falling back to UTC offset',
        );
        // Try to find timezone by UTC offset from the device
        try {
          final now = DateTime.now();
          final offset = now.timeZoneOffset;
          // Search for a timezone matching this offset
          final candidates = tz.timeZoneDatabase.locations.values
              .where(
                (loc) => loc.currentTimeZone.offset == offset.inMilliseconds,
              )
              .toList();
          if (candidates.isNotEmpty) {
            tz.setLocalLocation(candidates.first);
            debugPrint('Timezone resolved via offset to: ${tz.local.name}');
          } else {
            tz.setLocalLocation(tz.UTC);
            debugPrint(
              'No timezone found for offset ${offset.inHours}h — using UTC',
            );
          }
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
          debugPrint('Timezone offset fallback failed — using UTC');
        }
      }
    } catch (e) {
      debugPrint('Could not resolve local timezone: $e');
      // Try offset-based fallback even when FlutterTimezone fails
      try {
        final offset = DateTime.now().timeZoneOffset;
        final candidates = tz.timeZoneDatabase.locations.values
            .where((loc) => loc.currentTimeZone.offset == offset.inMilliseconds)
            .toList();
        if (candidates.isNotEmpty) {
          tz.setLocalLocation(candidates.first);
          debugPrint('Timezone resolved via offset to: ${tz.local.name}');
        }
      } catch (_) {
        // Already defaults to UTC
      }
    }
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

  /// Schedules a notification at [when], a local wall-clock time.
  /// If [matchDateTimeComponents] is provided (e.g. [DateTimeComponents.time]),
  /// the notification repeats at that time.
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    DateTimeComponents? matchDateTimeComponents,
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
      matchDateTimeComponents: matchDateTimeComponents,
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
