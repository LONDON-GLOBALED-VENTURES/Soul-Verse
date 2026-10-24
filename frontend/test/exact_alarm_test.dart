import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soulverse/features/reminders/data/notification_scheduler.dart';

void main() {
  group('schedule mode', () {
    test('exact when the user allows exact alarms', () {
      expect(
        NotificationScheduler.scheduleModeFor(true),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test('inexact when exact alarms are denied (Android 14+ default)', () {
      expect(
        NotificationScheduler.scheduleModeFor(false),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });

    test('exact when no permission is needed (older Android)', () {
      expect(
        NotificationScheduler.scheduleModeFor(null),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });
  });

  test('permission is not reported as granted when it can\'t be confirmed', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // No real notification plugin runs in tests: initialising fails or the
    // platform is unsupported. Previously both paths answered "granted".
    expect(await NotificationScheduler().requestPermission(), isFalse);
  });

  test('manifest avoids permissions Google Play restricts', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, isNot(contains('android.permission.USE_EXACT_ALARM')));
    // SCHEDULE_EXACT_ALARM must not be capped, or Android 13+ gets no exact alarms.
    expect(RegExp(r'SCHEDULE_EXACT_ALARM"\s*/>').hasMatch(manifest), isTrue);
  });
}
