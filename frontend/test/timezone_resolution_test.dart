import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:soulverse/features/reminders/data/notification_scheduler.dart';

// 15 Jan 2026 (northern winter); six months later is mid-July.
final _jan = DateTime.utc(2026, 1, 15).millisecondsSinceEpoch;
final _jul = DateTime.utc(2026, 7, 16).millisecondsSinceEpoch;

tz.Location _resolve(
  String? id, {
  required Duration now,
  required Duration later,
}) => NotificationScheduler.resolveLocation(
  id,
  nowMillis: _jan,
  offsetNow: now,
  offsetInSixMonths: later,
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('uses the device zone when its name is known', () {
    final location = _resolve(
      'Asia/Kolkata',
      now: const Duration(hours: 5, minutes: 30),
      later: const Duration(hours: 5, minutes: 30),
    );
    expect(location.name, 'Asia/Kolkata');
  });

  test('an unknown name falls back to a zone with the same offset', () {
    final location = _resolve(
      'Not/A_Zone',
      now: const Duration(hours: 5, minutes: 30),
      later: const Duration(hours: 5, minutes: 30),
    );
    expect(location.name, isNot('UTC'));
    expect(
      location.timeZone(_jan).offset,
      const Duration(hours: 5, minutes: 30),
    );
  });

  test('the fallback also matches summer time, not just today\'s offset', () {
    // A Central European device: UTC+1 in winter, UTC+2 in summer.
    final location = _resolve(
      'Not/A_Zone',
      now: const Duration(hours: 1),
      later: const Duration(hours: 2),
    );
    // A zone without summer time (e.g. Africa/Lagos) would shift reminders by an hour in July.
    expect(location.timeZone(_jan).offset, const Duration(hours: 1));
    expect(location.timeZone(_jul).offset, const Duration(hours: 2));
  });

  test('a missing name (plugin failure) also falls back by offset', () {
    final location = _resolve(
      null,
      now: const Duration(hours: -5),
      later: const Duration(hours: -4),
    );
    expect(location.timeZone(_jan).offset, const Duration(hours: -5));
    expect(location.timeZone(_jul).offset, const Duration(hours: -4));
  });

  test('UTC only when no zone matches at all', () {
    final location = _resolve(
      null,
      now: const Duration(hours: 13, minutes: 47),
      later: const Duration(hours: 13, minutes: 47),
    );
    expect(location, tz.UTC);
  });
}
