import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_states.dart';
import '../../reminders/application/reminders_provider.dart';
import '../../reminders/data/notification_scheduler.dart';
import '../../reminders/data/reminder_settings.dart';

class MorePage extends ConsumerStatefulWidget {
  const MorePage({super.key});

  @override
  ConsumerState<MorePage> createState() => _MorePageState();
}

class _MorePageState extends ConsumerState<MorePage> {
  bool _permissionDenied = false;

  String _formatTime(BuildContext context, int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  Future<void> _pickTime(
    ReminderSettings settings, {
    required bool isMorning,
  }) async {
    final currentSlot = isMorning ? settings.morning : settings.evening;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentSlot.hour, minute: currentSlot.minute),
      builder: (pickerContext, child) {
        return Theme(
          data: Theme.of(pickerContext).copyWith(
            colorScheme: Theme.of(pickerContext).colorScheme.copyWith(
              primary: AppColors.accent,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final updatedSlot = currentSlot.copyWith(
        hour: picked.hour,
        minute: picked.minute,
      );
      final updated = isMorning
          ? settings.copyWith(morning: updatedSlot)
          : settings.copyWith(evening: updatedSlot);
      await ref.read(remindersProvider.notifier).save(updated);
    }
  }

  Future<void> _toggleReminder(
    ReminderSettings settings, {
    required bool isMorning,
    required bool enabled,
  }) async {
    if (enabled) {
      final scheduler = ref.read(notificationSchedulerProvider);
      final granted = await scheduler.requestPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _permissionDenied = true;
        });
        _showPermissionDialog();
        return;
      }
    }

    if (!mounted) return;
    if (_permissionDenied) {
      setState(() {
        _permissionDenied = false;
      });
    }

    final updated = isMorning
        ? settings.copyWith(
            morning: settings.morning.copyWith(enabled: enabled),
          )
        : settings.copyWith(
            evening: settings.evening.copyWith(enabled: enabled),
          );
    await ref.read(remindersProvider.notifier).save(updated);
  }

  void _showPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notifications Disabled'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To receive daily verse reminders, please enable notifications for SoulVerse in your device settings:',
            ),
            SizedBox(height: 12),
            Text('1. Open your device Settings'),
            Text('2. Select Notifications (or Apps > SoulVerse)'),
            Text('3. Turn on "Allow notifications"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text('Settings', style: textTheme.headlineMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Reminders', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Receive inspiring verses and reflections at times you choose.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: remindersAsync.when(
                  data: (settings) => Column(
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _ReminderTile(
                              icon: Icons.wb_sunny_outlined,
                              title: 'Morning Verse',
                              timeText: _formatTime(
                                context,
                                settings.morning.hour,
                                settings.morning.minute,
                              ),
                              enabled: settings.morning.enabled,
                              onTapTime: () => _pickTime(
                                settings,
                                isMorning: true,
                              ),
                              onToggle: (enabled) => _toggleReminder(
                                settings,
                                isMorning: true,
                                enabled: enabled,
                              ),
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _ReminderTile(
                              icon: Icons.nightlight_outlined,
                              title: 'Evening Verse',
                              timeText: _formatTime(
                                context,
                                settings.evening.hour,
                                settings.evening.minute,
                              ),
                              enabled: settings.evening.enabled,
                              onTapTime: () => _pickTime(
                                settings,
                                isMorning: false,
                              ),
                              onToggle: (enabled) => _toggleReminder(
                                settings,
                                isMorning: false,
                                enabled: enabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_permissionDenied) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.tile),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.notifications_off_outlined,
                                color: AppColors.accent,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications are disabled',
                                      style: textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'To receive reminders, please open your device Settings > Apps > SoulVerse > Notifications and enable "Allow notifications".',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Dismiss',
                                onPressed: () => setState(() {
                                  _permissionDenied = false;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  loading: () => const LoadingBox(height: 140),
                  error: (_, _) => ErrorRetry(
                    message: 'We couldn\'t load your reminder settings.',
                    onRetry: () => ref.invalidate(remindersProvider),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                child: Text('About', style: textTheme.titleLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SoulVerse', style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Daily verses and peaceful reflections for your journey.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.timeText,
    required this.enabled,
    required this.onTapTime,
    required this.onToggle,
  });

  final IconData icon;
  final String title;
  final String timeText;
  final bool enabled;
  final VoidCallback onTapTime;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onTapTime,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeText,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeTrackColor: AppColors.accent,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
