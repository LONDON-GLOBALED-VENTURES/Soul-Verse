import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/legal_links.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_states.dart';
import '../../auth/application/auth_service.dart';
import '../../auth/presentation/delete_account_flow.dart';
import '../../auth/presentation/widgets/google_sign_in_button.dart';
import '../../reminders/application/exact_alarms_provider.dart';
import '../../reminders/application/reminder_service.dart';
import '../../reminders/application/reminders_provider.dart';
import '../../reminders/data/notification_scheduler.dart';
import '../../reminders/data/reminder_settings.dart';
import '../../subscription/application/premium_providers.dart';
import '../../subscription/presentation/premium_upgrade_sheet.dart';
import '../../subscription/presentation/subscription_actions.dart';

class MorePage extends ConsumerStatefulWidget {
  const MorePage({super.key});

  @override
  ConsumerState<MorePage> createState() => _MorePageState();
}

class _MorePageState extends ConsumerState<MorePage> {
  bool _permissionDenied = false;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The exact-alarm setting is changed outside the app, so re-check on return.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(exactAlarmsAllowedProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _allowExactAlarms() async {
    await ref.read(notificationSchedulerProvider).openExactAlarmSettings();
    ref.invalidate(exactAlarmsAllowedProvider);
  }

  String _formatTime(BuildContext context, int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  Future<void> _pickTime(ReminderSettings settings) async {
    final currentSlot = settings.daily;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentSlot.hour,
        minute: currentSlot.minute,
      ),
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
      await ref
          .read(remindersProvider.notifier)
          .save(settings.copyWith(daily: updatedSlot));
    }
  }

  Future<void> _toggleReminder(
    ReminderSettings settings, {
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
    if (_permissionDenied && !enabled) {
      setState(() {
        _permissionDenied = false;
      });
    }

    final updated = settings.copyWith(
      daily: settings.daily.copyWith(enabled: enabled),
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
    final exactAlarmsAllowed = ref.watch(exactAlarmsAllowedProvider).value;

    // Once allowed, reschedule so the pending reminders become exact right away.
    ref.listen(exactAlarmsAllowedProvider, (previous, next) {
      final settings = ref.read(remindersProvider).value;
      if (previous?.value == false && next.value == true && settings != null) {
        ref.read(reminderServiceProvider).reschedule(settings);
      }
    });

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
            if (!ref.watch(billingEnabledProvider))
              const SliverToBoxAdapter(child: _BillingOffBanner()),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(child: _AccountCard()),
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
                        child: _ReminderTile(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Daily Verse',
                          timeText: _formatTime(
                            context,
                            settings.daily.hour,
                            settings.daily.minute,
                          ),
                          enabled: settings.daily.enabled,
                          onTapTime: () => _pickTime(settings),
                          onToggle: (enabled) =>
                              _toggleReminder(settings, enabled: enabled),
                        ),
                      ),
                      if (settings.daily.enabled &&
                          exactAlarmsAllowed == false) ...[
                        const SizedBox(height: 16),
                        _ExactAlarmCard(onAllow: _allowExactAlarms),
                      ],
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
                        if (termsUrl.isNotEmpty || privacyUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (termsUrl.isNotEmpty)
                                TextButton(
                                  onPressed: () => openExternalUrl(termsUrl),
                                  child: const Text('Terms of Use'),
                                ),
                              if (privacyUrl.isNotEmpty)
                                TextButton(
                                  onPressed: () => openExternalUrl(privacyUrl),
                                  child: const Text('Privacy Policy'),
                                ),
                            ],
                          ),
                        ],
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

/// Shown on Android 14+ when "Alarms & reminders" is off, which can delay
/// reminders by up to an hour.
class _ExactAlarmCard extends StatelessWidget {
  const _ExactAlarmCard({required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.alarm_outlined, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get your verse right on time',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your phone may deliver reminders up to an hour late. '
                  'Allow "Alarms & reminders" for SoulVerse so they arrive '
                  'at the time you chose.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: onAllow, child: const Text('Allow')),
              ],
            ),
          ),
        ],
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

    return InkWell(
      onTap: () => onToggle(!enabled),
      child: Padding(
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 2,
                      ),
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
    // From the app store (or unlocked when billing is off for QA).
    final isPremium = ref.watch(isPremiumProvider);
    final billingEnabled = ref.watch(billingEnabledProvider);

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
                              InkWell(
                                onTap: isPremium
                                    ? null
                                    : () => showPremiumUpgradeSheet(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPremium
                                        ? const Color(0xFFFFD700)
                                              .withValues(alpha: 0.18)
                                        : AppColors.accent.withValues(
                                            alpha: 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isPremium) ...[
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 13,
                                          color: Color(0xFFD4AF37),
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                      Text(
                                        isPremium
                                            ? 'Premium Member'
                                            : 'Free Plan',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: isPremium
                                              ? const Color(0xFFB8860B)
                                              : AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(
                                    alpha: 0.08,
                                  ),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
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
                const SizedBox(height: 12),
                const Divider(height: 1),
                if (billingEnabled)
                  isPremium
                      ? _AccountTile(
                          icon: Icons.credit_card,
                          label: 'Manage subscription',
                          onTap: () => openManageSubscription(context, ref),
                        )
                      : _AccountTile(
                          icon: Icons.restore,
                          label: 'Restore purchases',
                          onTap: () => restorePurchases(context, ref),
                        ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(
                    Icons.block,
                    color: AppColors.textSecondary,
                  ),
                  title: Text('Blocked users', style: textTheme.titleSmall),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.blockedUsers),
                ),
                const DeleteAccountButton(),
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

/// Shown when the backend has billing switched off (QA/staging builds), so
/// testers know Premium is unlocked without a subscription.
class _BillingOffBanner extends StatelessWidget {
  const _BillingOffBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6C27A)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              size: 20,
              color: Color(0xFF8A6D1F),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Test build: billing off. All Premium features are unlocked.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5C4813),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row in the signed-in account card (e.g. Manage subscription).
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
        Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}
