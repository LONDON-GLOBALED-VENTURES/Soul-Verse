import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/retry_policy.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home_widget/home_widget_service.dart';
import 'features/reminders/application/reminder_service.dart';
import 'features/reminders/application/reminders_provider.dart';
import 'features/verses/application/verses_providers.dart';

void main() {
  runApp(const ProviderScope(retry: appRetry, child: SoulVerseApp()));
}

class SoulVerseApp extends ConsumerWidget {
  const SoulVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Refresh the home-screen widgets whenever today's verse loads.
    ref.listen(dailyVerseProvider, (_, next) {
      next.whenData(ref.read(homeWidgetServiceProvider).sync);
    });

    // Reschedule reminders on launch (settings load) and whenever they change,
    // keeping the upcoming verse notifications up to date (see ReminderService).
    ref.listen(remindersProvider, (_, next) {
      next.whenData(ref.read(reminderServiceProvider).reschedule);
    });

    return MaterialApp.router(
      title: 'SoulVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
