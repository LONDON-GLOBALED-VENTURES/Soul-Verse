import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:soulverse/features/reminders/application/reminder_service.dart';
import 'package:soulverse/features/reminders/application/reminders_provider.dart';
import 'package:soulverse/features/reminders/data/notification_scheduler.dart';
import 'package:soulverse/features/reminders/data/reminder_settings.dart';
import 'package:soulverse/features/verses/data/models/daily_verse.dart';
import 'package:soulverse/features/verses/data/models/mood.dart';
import 'package:soulverse/features/verses/data/models/verse.dart';
import 'package:soulverse/features/verses/data/models/verse_template.dart';
import 'package:soulverse/features/verses/data/verses_api.dart';

class _Scheduled {
  _Scheduled(this.id, this.when, this.title, this.body);
  final int id;
  final DateTime when;
  final String title;
  final String body;
}

class _FakeScheduler extends NotificationScheduler {
  final scheduled = <_Scheduled>[];
  var cancelAllCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async => scheduled.add(_Scheduled(id, when, title, body));
}

/// Returns a distinct verse per date: "Verse for 2026-10-02" etc.
class _FakeApi implements VersesApi {
  _FakeApi({this.offline = false});
  final bool offline;
  (String, int)? rangeRequest;

  @override
  Future<List<DailyVerse>> getDailyRange(String start, int days) async {
    rangeRequest = (start, days);
    if (offline) throw Exception('no network');
    final first = DateTime.parse(start);
    return [
      for (var i = 0; i < days; i++)
        _entry(
          DateTime(
            first.year,
            first.month,
            first.day + i,
          ).toIso8601String().substring(0, 10),
        ),
    ];
  }

  DailyVerse _entry(String date) => DailyVerse(
    date: date,
    verse: Verse(
      id: 'v-$date',
      text: 'Verse for $date',
      reference: 'Ref $date',
      translation: 'KJV',
      moods: const [],
      reflection: 'Reflection for $date',
    ),
    template: const VerseTemplate(
      id: 't',
      imageUrl: 'http://test/t.png',
      moods: [],
      textColor: '#FFFFFF',
      overlayOpacity: 0.3,
    ),
  );

  @override
  Future<DailyVerse> getDailyVerse({String? date}) =>
      throw UnimplementedError();
  @override
  Future<List<Mood>> getMoods() => throw UnimplementedError();
  @override
  Future<List<VerseTemplate>> getTemplates({String? mood}) =>
      throw UnimplementedError();
  @override
  Future<List<Verse>> getVerses({String? mood}) => throw UnimplementedError();
}

// 1 Oct 2026, 09:00 local: today's 08:00 has passed.
final _now = DateTime(2026, 10, 1, 9);

ReminderSettings _settings({bool enabled = false, int hour = 8, int minute = 0}) =>
    ReminderSettings.defaults.copyWith(
      daily: ReminderSlot(enabled: enabled, hour: hour, minute: minute),
    );

void main() {
  late _FakeScheduler scheduler;

  setUp(() => scheduler = _FakeScheduler());

  ReminderService service(_FakeApi api) =>
      ReminderService(api, scheduler, now: () => _now);

  test('nothing is scheduled when reminders are off', () async {
    final api = _FakeApi();
    await service(api).reschedule(ReminderSettings.defaults);

    expect(scheduler.cancelAllCalls, 1);
    expect(scheduler.scheduled, isEmpty);
    expect(api.rangeRequest, isNull, reason: 'no need to fetch verses');
  });

  test('schedules 14 days ahead, skipping times already past', () async {
    final api = _FakeApi();
    await service(api).reschedule(_settings(enabled: true, hour: 8));

    expect(api.rangeRequest, ('2026-10-01', 14));
    // Today's 8:00 has already passed at 9:00: 13 days are scheduled.
    expect(scheduler.scheduled, hasLength(13));
    expect(scheduler.scheduled.every((s) => s.when.isAfter(_now)), isTrue);
    expect(scheduler.scheduled.map((s) => s.id).toSet(), hasLength(13));
    expect(scheduler.scheduled.first.when, DateTime(2026, 10, 2, 8));
    expect(scheduler.scheduled.last.when, DateTime(2026, 10, 14, 8));
  });

  test('each reminder shows that day\'s verse quote', () async {
    await service(_FakeApi())
        .reschedule(_settings(enabled: true, hour: 8));

    final oct2 = scheduler.scheduled.firstWhere(
      (s) => s.when == DateTime(2026, 10, 2, 8),
    );
    expect(oct2.title, 'Daily Verse');
    expect(oct2.body, '“Verse for 2026-10-02” — Ref 2026-10-02');
  });

  test('schedules today when reminder time is in the future', () async {
    final settings = _settings(enabled: true, hour: 10, minute: 30);
    await service(_FakeApi()).reschedule(settings);

    // 10:30 AM is after 9:00 AM, so today + next 13 days = 14 reminders.
    expect(scheduler.scheduled, hasLength(14));
    expect(
      scheduler.scheduled.every((s) => s.title == 'Daily Verse'),
      isTrue,
    );
    expect(scheduler.scheduled.first.when, DateTime(2026, 10, 1, 10, 30));
  });

  test('offline still schedules reminders with generic text', () async {
    await service(_FakeApi(offline: true))
        .reschedule(_settings(enabled: true, hour: 10));

    expect(scheduler.scheduled, hasLength(14));
    expect(
      scheduler.scheduled.first.body,
      'Take a moment with today\'s verse.',
    );
  });

  test('rescheduling replaces previous reminders', () async {
    final s = service(_FakeApi());
    await s.reschedule(_settings(enabled: true, hour: 8));
    await s.reschedule(_settings(enabled: true, hour: 10));

    expect(scheduler.scheduled, hasLength(14));
    expect(scheduler.cancelAllCalls, 2);
  });

  group('settings', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('default to off at 8:00 am', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = await container.read(remindersProvider.future);

      expect(settings.anyEnabled, isFalse);
      expect((settings.daily.hour, settings.daily.minute), (8, 0));
    });

    test('are saved across app restarts', () async {
      final first = ProviderContainer();
      await first
          .read(remindersProvider.notifier)
          .save(_settings(enabled: true, hour: 9));
      first.dispose();

      final restarted = ProviderContainer();
      addTearDown(restarted.dispose);
      final settings = await restarted.read(remindersProvider.future);
      expect(settings.daily.enabled, isTrue);
      expect(settings.daily.hour, 9);
    });

    test('unreadable data falls back to defaults', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({'reminder_settings': '{'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        (await container.read(remindersProvider.future)).anyEnabled,
        isFalse,
      );
    });
  });
}
