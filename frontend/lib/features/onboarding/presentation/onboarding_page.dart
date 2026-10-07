import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/widgets/sign_in_prompt_dialog.dart';
import '../../reminders/application/reminders_provider.dart';
import '../../reminders/data/notification_scheduler.dart';
import '../../reminders/data/reminder_settings.dart';
import '../application/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedIntent = 'anxious';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    ref.read(onboardingCompletedProvider.notifier).complete();
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      ref.read(onboardingCompletedProvider.notifier).complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation: Back Button, Step Indicator & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      color: AppColors.textPrimary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _prevPage,
                    ),
                    const SizedBox(width: 12),
                  ],
                  _StepIndicator(currentPage: _currentPage, totalSteps: 3),
                  const Spacer(),
                  TextButton(
                    onPressed: _onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // PageView containing onboarding slides
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomeStepView(
                    onBegin: _nextPage,
                    onSignIn: () async {
                      final signedIn = await showSignInPromptDialog(
                        context,
                        title: 'Welcome Back',
                        message:
                            'Sign in to access your saved verses, prayers, and personal journey.',
                        icon: Icons.account_circle_outlined,
                      );
                      if (signedIn && context.mounted) {
                        await ref
                            .read(onboardingCompletedProvider.notifier)
                            .complete();
                      }
                    },
                  ),
                  _IntentStepView(
                    selectedIntent: _selectedIntent,
                    onSelectIntent: (intent) =>
                        setState(() => _selectedIntent = intent),
                    onContinue: () async {
                      await ref
                          .read(onboardingCompletedProvider.notifier)
                          .saveIntent(_selectedIntent);
                      _nextPage();
                    },
                  ),
                  const _HabitStepView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slide 1: Welcome Screen with charismatic, reverent spiritual copy
class _WelcomeStepView extends StatelessWidget {
  const _WelcomeStepView({
    required this.onBegin,
    required this.onSignIn,
  });

  final VoidCallback onBegin;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Spiritual Emblem Container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 46,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Charismatic Tag Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'A SACRED DAILY PAUSE FOR YOUR SOUL',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Charismatic Headline
          Text(
            'Draw Near to God',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontFamily: AppFonts.serif,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 34,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          // Subtitle
          Text(
            'Walk closer with God every day through living Scripture, reflection, and the fellowship of brothers and sisters in Christ.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          // Scripture Quote Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.accent,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“Draw near to God, and He will draw near to you.”',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '— James 4:8',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: onBegin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Begin Your Journey',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Existing Account Sign In
          TextButton(
            onPressed: onSignIn,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                children: const [
                  TextSpan(text: 'Already part of the family? '),
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Animated 3-dot step indicator
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentPage,
    required this.totalSteps,
  });

  final int currentPage;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent
                : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _IntentOption {
  final String id;
  final String emoji;
  final String title;
  final String description;

  const _IntentOption({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
  });
}

/// Slide 2: Spiritual Intent & Heart Questionnaire
class _IntentStepView extends StatelessWidget {
  const _IntentStepView({
    required this.selectedIntent,
    required this.onSelectIntent,
    required this.onContinue,
  });

  final String selectedIntent;
  final ValueChanged<String> onSelectIntent;
  final VoidCallback onContinue;

  static const List<_IntentOption> options = [
    _IntentOption(
      id: 'anxious',
      emoji: '🕊️',
      title: 'Inner Peace & Rest',
      description: 'Be still and release all anxiety into His hands.',
    ),
    _IntentOption(
      id: 'hopeful',
      emoji: '🌅',
      title: 'Living Hope & Renewal',
      description: "Start each morning rooted in God's promises.",
    ),
    _IntentOption(
      id: 'need-strength',
      emoji: '💪',
      title: 'Unshakable Strength',
      description: 'Stand firm and overcome battles through faith.',
    ),
    _IntentOption(
      id: 'grateful',
      emoji: '🙏',
      title: 'Praise & Overflowing Joy',
      description: "Celebrate God's goodness with a thankful heart.",
    ),
    _IntentOption(
      id: 'prayers',
      emoji: '🤝',
      title: 'Fellowship & Prayer',
      description: 'Lift up and be lifted up together in Christ.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            'Where is your heart today?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: AppFonts.serif,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'God meets you wherever you are. What does your spirit need most right now?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          // List of selectable charismatic cards
          ...options.map((opt) {
            final isSelected = opt.id == selectedIntent;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onSelectIntent(opt.id),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            opt.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              opt.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color:
                            isSelected ? AppColors.accent : AppColors.placeholder,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Slide 3: Daily Habit & Notification Setup
class _HabitStepView extends ConsumerStatefulWidget {
  const _HabitStepView();

  @override
  ConsumerState<_HabitStepView> createState() => _HabitStepViewState();
}

class _HabitStepViewState extends ConsumerState<_HabitStepView> {
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  bool _isSaving = false;

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.accent,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderTime = picked;
        _reminderEnabled = true;
      });
    }
  }

  Future<void> _onBlessWalk() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_reminderEnabled) {
        final scheduler = ref.read(notificationSchedulerProvider);
        final granted = await scheduler.requestPermission();
        if (granted) {
          final settings = ReminderSettings(
            daily: ReminderSlot(
              enabled: _reminderEnabled,
              hour: _reminderTime.hour,
              minute: _reminderTime.minute,
            ),
          );
          await ref.read(remindersProvider.notifier).save(settings);
        }
      }
    } catch (e) {
      debugPrint('Error enabling habit reminders: $e');
    } finally {
      if (mounted) {
        await ref.read(onboardingCompletedProvider.notifier).complete();
        setState(() => _isSaving = false);
      }
    }
  }

  void _onSkipLater() {
    ref.read(onboardingCompletedProvider.notifier).complete();
  }

  Widget _buildReminderCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTapTime,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.border,
          width: enabled ? 1.5 : 1.0,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: enabled ? AppColors.accent : AppColors.placeholder,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
                activeTrackColor: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reminder Time',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: onTapTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: enabled
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color:
                            enabled ? AppColors.accent : AppColors.placeholder,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimeOfDay(time),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: enabled
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color:
                            enabled ? AppColors.accent : AppColors.placeholder,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            'Make Room for His Presence',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: AppFonts.serif,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A gentle daily rhythm to nourish your spirit and stay connected with God.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          // Daily Reminder Card
          _buildReminderCard(
            context: context,
            title: 'Daily Verse of the Day',
            subtitle: 'Awaken your heart with His truth before the day rushes in.',
            icon: Icons.wb_sunny_rounded,
            enabled: _reminderEnabled,
            time: _reminderTime,
            onToggle: (val) => setState(() => _reminderEnabled = val),
            onTapTime: _selectTime,
          ),
          const SizedBox(height: 20),
          // Scripture Promise Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '“Your word is a lamp to my feet and a light to my path.” — Psalm 119:105',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isSaving ? null : _onBlessWalk,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : const Text(
                      'Bless My Daily Walk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Secondary Skip Button
          TextButton(
            onPressed: _isSaving ? null : _onSkipLater,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text(
              "I'll set this later",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
