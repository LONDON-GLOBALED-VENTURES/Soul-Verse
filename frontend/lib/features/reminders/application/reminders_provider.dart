import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/reminder_settings.dart';
import '../data/reminder_settings_repository.dart';

part 'reminders_provider.g.dart';

/// The user's reminder settings. Changes are saved and the app reschedules via main.dart.
@Riverpod(keepAlive: true)
class Reminders extends _$Reminders {
  @override
  Future<ReminderSettings> build() =>
      ref.watch(reminderSettingsRepositoryProvider).load();

  Future<void> save(ReminderSettings settings) async {
    await ref.read(reminderSettingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }
}
