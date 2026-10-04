import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_states.dart';
import '../../auth/application/auth_service.dart';
import '../../auth/presentation/widgets/google_sign_in_button.dart';
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
                child: Text('Profile', style: textTheme.headlineMedium),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _AccountCard(),
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

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of SoulVerse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SoulVerse Account',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sign in to personalize your experience and sync favourites.',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GoogleSignInButton(
                      isLoading: authState.isLoading,
                      onPressed: () =>
                          ref.read(authProvider.notifier).signInWithGoogle(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final status = user.prayerStats.status;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : 'U',
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.accent,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.subscription.isPremium
                                      ? 'Premium Member'
                                      : 'Free Plan',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.displayTitle,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign Out',
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _confirmSignOut(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spiritual Rank: ${status.displayTitle}',
                      style: textTheme.titleSmall,
                    ),
                    if (status.nextThreshold != null)
                      Text(
                        '${status.currentLikes} / ${status.nextThreshold} Amens',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        'Max Rank reached! 👑',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: status.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                if (status.nextTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Next milestone: ${status.nextTitle}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PrayerStatItem(
                      label: 'Prayers Shared',
                      value: '${user.prayerStats.prayersShared}',
                    ),
                    _PrayerStatItem(
                      label: 'Amens Received',
                      value: '${user.prayerStats.likesReceived}',
                    ),
                    _PrayerStatItem(
                      label: 'Prayers Offered',
                      value: '${user.prayerStats.likesGiven}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const LoadingBox(height: 96),
      error: (_, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not check account status',
                  style: textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(authProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerStatItem extends StatelessWidget {
  const _PrayerStatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
