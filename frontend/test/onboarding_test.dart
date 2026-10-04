import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:soulverse/core/theme/app_theme.dart';
import 'package:soulverse/features/onboarding/application/onboarding_provider.dart';
import 'package:soulverse/features/onboarding/data/onboarding_repository.dart';
import 'package:soulverse/features/onboarding/presentation/onboarding_page.dart';
import 'package:soulverse/features/reminders/data/notification_scheduler.dart';

class _FakeScheduler extends NotificationScheduler {
  bool granted = true;

  @override
  Future<bool> requestPermission() async => granted;
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('OnboardingRepository', () {
    test('starts with uncompleted onboarding and null intent', () async {
      final repo = OnboardingRepository(SharedPreferencesAsync());
      expect(await repo.hasCompletedOnboarding(), isFalse);
      expect(await repo.getInitialIntent(), isNull);
    });

    test('completing onboarding sets hasCompleted to true', () async {
      final repo = OnboardingRepository(SharedPreferencesAsync());
      await repo.completeOnboarding();
      expect(await repo.hasCompletedOnboarding(), isTrue);
    });

    test('saving intent persists intent string', () async {
      final repo = OnboardingRepository(SharedPreferencesAsync());
      await repo.saveInitialIntent('hopeful');
      expect(await repo.getInitialIntent(), 'hopeful');
    });
  });

  group('OnboardingNotifier', () {
    test('initial value is false and complete updates to true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = await container.read(onboardingCompletedProvider.future);
      expect(initial, isFalse);

      await container.read(onboardingCompletedProvider.notifier).complete();
      final completed = await container.read(onboardingCompletedProvider.future);
      expect(completed, isTrue);

      final repo = container.read(onboardingRepositoryProvider);
      expect(await repo.hasCompletedOnboarding(), isTrue);
    });

    test('saveIntent writes intent to repository', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(onboardingCompletedProvider.notifier).saveIntent('grateful');
      final repo = container.read(onboardingRepositoryProvider);
      expect(await repo.getInitialIntent(), 'grateful');
    });
  });

  group('OnboardingPage Widget Tests', () {
    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          notificationSchedulerProvider.overrideWithValue(_FakeScheduler()),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Widget createWidget(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingPage(),
        ),
      );
    }

    testWidgets('renders Slide 1 (Welcome) and Skip button completes onboarding', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createContainer();
      await tester.pumpWidget(createWidget(container));
      await tester.pumpAndSettle();

      expect(find.text('Draw Near to God'), findsOneWidget);
      expect(find.text('Begin Your Journey'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      final completed = await container.read(onboardingCompletedProvider.future);
      expect(completed, isTrue);
    });

    testWidgets('advances from Welcome to Intent slide, and Back button returns', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createContainer();
      await tester.pumpWidget(createWidget(container));
      await tester.pumpAndSettle();

      // Tap Begin Your Journey
      await tester.tap(find.text('Begin Your Journey'));
      await tester.pumpAndSettle();

      // Should be on Step 2
      expect(find.text('Where is your heart today?'), findsOneWidget);
      expect(find.text('Inner Peace & Rest'), findsOneWidget);

      // Back button appears
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back on Step 1
      expect(find.text('Draw Near to God'), findsOneWidget);
    });

    testWidgets('selects intent and continues to Habit slide', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createContainer();
      await tester.pumpWidget(createWidget(container));
      await tester.pumpAndSettle();

      // Slide 1 -> Slide 2
      await tester.tap(find.text('Begin Your Journey'));
      await tester.pumpAndSettle();

      // Select Living Hope & Renewal
      await tester.tap(find.text('Living Hope & Renewal'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should be on Step 3
      expect(find.text('Make Room for His Presence'), findsOneWidget);
      expect(find.text('Morning Verse of the Day'), findsOneWidget);
      expect(find.text('Evening Reflection & Peace'), findsOneWidget);
      expect(find.text('Bless My Daily Walk'), findsOneWidget);
      expect(find.text("I'll set this later"), findsOneWidget);

      // Intent should be saved
      final repo = container.read(onboardingRepositoryProvider);
      expect(await repo.getInitialIntent(), 'hopeful');
    });

    testWidgets('tapping "Bless My Daily Walk" requests permission and completes onboarding', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createContainer();
      await tester.pumpWidget(createWidget(container));
      await tester.pumpAndSettle();

      // Move to Slide 2
      await tester.tap(find.text('Begin Your Journey'));
      await tester.pumpAndSettle();

      // Move to Slide 3
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap Bless My Daily Walk
      await tester.ensureVisible(find.text('Bless My Daily Walk'));
      await tester.tap(find.text('Bless My Daily Walk'));
      await tester.pumpAndSettle();

      final completed = await container.read(onboardingCompletedProvider.future);
      expect(completed, isTrue);
    });

    testWidgets('tapping "I\'ll set this later" completes onboarding', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createContainer();
      await tester.pumpWidget(createWidget(container));
      await tester.pumpAndSettle();

      // Move to Slide 2
      await tester.tap(find.text('Begin Your Journey'));
      await tester.pumpAndSettle();

      // Move to Slide 3
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap I'll set this later
      await tester.ensureVisible(find.text("I'll set this later"));
      await tester.tap(find.text("I'll set this later"));
      await tester.pumpAndSettle();

      final completed = await container.read(onboardingCompletedProvider.future);
      expect(completed, isTrue);
    });
  });
}

