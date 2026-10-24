import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notification_scheduler.dart';

part 'exact_alarms_provider.g.dart';

/// Whether reminders can be delivered on time. Invalidate after the user may have
/// changed the system setting (e.g. when the app returns to the foreground).
@riverpod
Future<bool> exactAlarmsAllowed(Ref ref) =>
    ref.watch(notificationSchedulerProvider).canScheduleExactAlarms();
