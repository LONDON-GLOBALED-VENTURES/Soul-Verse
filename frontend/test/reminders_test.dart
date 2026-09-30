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

// 1 Oct 2026, 09:00 local: today's 07:00 has passed, today's 20:00 hasn't.
final _now = DateTime(2026, 10, 1, 9);

ReminderSettings _settings({bool morning = false, bool evening = false}) =>
    ReminderSettings.defaults.copyWith(
      morning: ReminderSettings.defaults.morning.copyWith(enabled: morning),
      evening: ReminderSettings.defaults.evening.copyWith(enabled: evening),
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
    await service(api).reschedule(_settings(morning: true, evening: true));

    expect(api.rangeRequest, ('2026-10-01', 14));
    // Today's morning already passed: 13 mornings + 14 evenings.
    expect(scheduler.scheduled, hasLength(27));
    expect(scheduler.scheduled.every((s) => s.when.isAfter(_now)), isTrue);
    expect(scheduler.scheduled.map((s) => s.id).toSet(), hasLength(27));
    expect(scheduler.scheduled.first.when, DateTime(2026, 10, 1, 20));
    expect(scheduler.scheduled.last.when, DateTime(2026, 10, 14, 20));
  });

  test('each reminder shows that day\'s verse', () async {
    await service(_FakeApi())
        .reschedule(_settings(morning: true, evening: true));

    final morningOct2 = scheduler.scheduled.firstWhere(
      (s) => s.when == DateTime(2026, 10, 2, 7),
    );
    expect(morningOct2.title, 'Your morning verse');
    expect(morningOct2.body, '“Verse for 2026-10-02” — Ref 2026-10-02');

    final eveningOct1 = scheduler.scheduled.firstWhere(
      (s) => s.when == DateTime(2026, 10, 1, 20),
    );
    expect(eveningOct1.title, 'Evening reflection');
    expect(eveningOct1.body, 'Reflection for 2026-10-01 (Ref 2026-10-01)');
  });

  test('only enabled reminders are scheduled, at the chosen time', () async {
    final settings = _settings(
      morning: true,
    ).copyWith(morning: const ReminderSlot(enabled: true, hour: 6, minute: 30));
    await service(_FakeApi()).reschedule(settings);

    expect(scheduler.scheduled, hasLength(13));
    expect(
      scheduler.scheduled.every((s) => s.title == 'Your morning verse'),
      isTrue,
    );
    expect(scheduler.scheduled.first.when, DateTime(2026, 10, 2, 6, 30));
  });

  test('offline still schedules reminders with generic text', () async {
    await service(_FakeApi(offline: true))
        .reschedule(_settings(morning: true, evening: true));

    expect(scheduler.scheduled, hasLength(27));
    expect(
      scheduler.scheduled.first.body,
      'Pause and reflect on today\'s verse.',
    );
  });

  test('rescheduling replaces previous reminders', () async {
    final s = service(_FakeApi());
    await s.reschedule(_settings(morning: true, evening: true));
    await s.reschedule(_settings(evening: true));

    expect(scheduler.scheduled, hasLength(14));
    expect(scheduler.cancelAllCalls, 2);
  });

  group('settings', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('default to off at 7:00 am and 8:00 pm', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = await container.read(remindersProvider.future);

      expect(settings.anyEnabled, isFalse);
      expect((settings.morning.hour, settings.morning.minute), (7, 0));
      expect((settings.evening.hour, settings.evening.minute), (20, 0));
    });

    test('are saved across app restarts', () async {
      final first = ProviderContainer();
      await first
          .read(remindersProvider.notifier)
          .save(_settings(evening: true));
      first.dispose();

      final restarted = ProviderContainer();
      addTearDown(restarted.dispose);
      final settings = await restarted.read(remindersProvider.future);
      expect(settings.evening.enabled, isTrue);
      expect(settings.morning.enabled, isFalse);
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
