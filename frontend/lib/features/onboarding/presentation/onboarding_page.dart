import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/widgets/sign_in_prompt_dialog.dart';
import '../application/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    ref.read(onboardingCompletedProvider.notifier).complete();
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
            // Top Navigation: Step Indicator & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
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
                  _PlaceholderStepView(
                    stepNumber: 2,
                    title: 'Where is your heart today?',
                    description: 'Personalize your daily walk with God.',
                    onContinue: _nextPage,
                  ),
                  _PlaceholderStepView(
                    stepNumber: 3,
                    title: 'Make Room for His Presence',
                    description: 'Set your daily scripture habit and reminders.',
                    onContinue: _nextPage,
                  ),
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

/// Placeholder for Steps 2 and 3 before their dedicated implementations
class _PlaceholderStepView extends StatelessWidget {
  const _PlaceholderStepView({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.onContinue,
  });

  final int stepNumber;
  final String title;
  final String description;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stepNumber',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: AppFonts.serif,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),
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
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
