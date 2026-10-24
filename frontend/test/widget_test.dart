import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:soulverse/core/widgets/verse_card.dart';
import 'package:soulverse/features/auth/application/auth_service.dart';
import 'package:soulverse/features/auth/data/auth_api.dart';
import 'package:soulverse/features/auth/data/models/user.dart';
import 'package:soulverse/features/home_widget/home_widget_service.dart';
import 'package:soulverse/features/reminders/data/notification_scheduler.dart';
import 'package:soulverse/features/share/data/share_service.dart';
import 'package:soulverse/features/verses/application/verses_providers.dart';
import 'package:soulverse/features/verses/data/models/daily_verse.dart';
import 'package:soulverse/features/verses/data/models/mood.dart';
import 'package:soulverse/features/verses/data/models/verse.dart';
import 'package:soulverse/features/verses/data/models/verse_template.dart';
import 'package:soulverse/features/verses/data/verses_api.dart';
import 'package:soulverse/main.dart';

const _stillVerse = Verse(
  id: 'ps-46-10',
  text: 'Be still, and know that I am God.',
  reference: 'Psalm 46:10',
  translation: 'KJV',
  moods: ['anxious'],
  reflection: 'Rest in Him.',
);

const _careVerse = Verse(
  id: '1pet-5-7',
  text: 'Casting all your care upon him; for he careth for you.',
  reference: '1 Peter 5:7',
  translation: 'KJV',
  moods: ['anxious'],
  reflection: 'Give Him what feels heavy.',
);

const _template = VerseTemplate(
  id: 'dawn',
  imageUrl: 'http://test/dawn.png',
  moods: ['anxious'],
  textColor: '#FFFFFF',
  overlayOpacity: 0.3,
);

class _FakeVersesApi implements VersesApi {
  final requestedDailyDates = <String?>[];

  @override
  Future<List<Mood>> getMoods() async => const [
    Mood(
      id: 'anxious',
      name: 'Anxious',
      title: 'Verses for Anxiety',
      imageUrl: 'http://test/mist.png',
    ),
  ];

  @override
  Future<List<Verse>> getVerses({String? mood}) async => const [
    _stillVerse,
    _careVerse,
  ];

  @override
  Future<DailyVerse> getDailyVerse({String? date}) async {
    requestedDailyDates.add(date);
    return const DailyVerse(
      date: '2026-01-01',
      verse: _stillVerse,
      template: _template,
    );
  }

  @override
  Future<List<DailyVerse>> getDailyRange(String start, int days) async => [];

  @override
  Future<List<VerseTemplate>> getTemplates({String? mood}) async => const [
    _template,
  ];
}

class _NoopScheduler extends NotificationScheduler {
  bool permissionGranted = true;
  var requestPermissionCalls = 0;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionGranted;
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {}
}

class _FakeHomeWidgetService implements HomeWidgetService {
  final syncedDates = <String>[];

  @override
  Future<void> sync(DailyVerse daily) async => syncedDates.add(daily.date);
}

class _FakeShareService implements ShareService {
  final calls = <String>[];
  Uint8List? lastPng;
  bool appInstalled = false;

  @override
  Future<SaveResult> saveToGallery(Uint8List png) async {
    calls.add('save');
    lastPng = png;
    return SaveResult.saved;
  }

  @override
  Future<bool> shareToApp(
    ShareTarget target,
    Uint8List png, {
    String? text,
  }) async {
    calls.add('app:${target.name}');
    lastPng = png;
    return appInstalled;
  }

  @override
  Future<void> shareToSystem(
    Uint8List png, {
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    calls.add('system');
    lastPng = png;
  }
}

class _FakeGoogleSignInService implements GoogleSignInService {
  String? idToken = 'mock-google-token:john@gmail.com:John Doe';
  var signOutCalls = 0;

  @override
  Future<String?> getGoogleIdToken() async => idToken;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

class _FakeAuthApi implements AuthApi {
  User currentUser = const User(
    id: 'usr_1',
    email: 'john@gmail.com',
    name: 'John Doe',
    subscription: UserSubscription.free,
  );

  @override
  Future<AuthSession> signInWithGoogle(String idToken) async {
    return AuthSession(
      user: currentUser,
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
    );
  }

  @override
  Future<String> refreshToken(String refreshToken) async => 'new-access-token';

  @override
  Future<User> getMe() async => currentUser;
}

void main() {
  late _FakeShareService shareService;
  late _FakeHomeWidgetService homeWidgetService;
  late _FakeVersesApi versesApi;
  late _NoopScheduler notificationScheduler;
  late _FakeGoogleSignInService googleSignInService;
  late _FakeAuthApi authApi;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('soulverse_test');
    // The image cache asks path_provider for a folder; plugins don't run in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tempDir.path,
        );
  });

  tearDownAll(() => tempDir.deleteSync(recursive: true));

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'has_completed_onboarding': true,
        });
    shareService = _FakeShareService();
    homeWidgetService = _FakeHomeWidgetService();
    versesApi = _FakeVersesApi();
    notificationScheduler = _NoopScheduler();
    googleSignInService = _FakeGoogleSignInService();
    authApi = _FakeAuthApi();
  });

  Widget app() => ProviderScope(
    overrides: [
      versesApiProvider.overrideWithValue(versesApi),
      shareServiceProvider.overrideWithValue(shareService),
      homeWidgetServiceProvider.overrideWithValue(homeWidgetService),
      notificationSchedulerProvider.overrideWithValue(notificationScheduler),
      googleSignInServiceProvider.overrideWithValue(googleSignInService),
      authApiProvider.overrideWithValue(authApi),
      moodVersesRandomProvider.overrideWithValue(null),
    ],
    child: const SoulVerseApp(),
  );

  // Capturing the preview renders a real image, which needs real async time.
  // Waits until the action finishes (the progress bar disappears).
  Future<void> tapAndWait(WidgetTester tester, String label) async {
    await tester.runAsync(() async {
      await tester.tap(find.text(label));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('share screen saves and shares the rendered verse image', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    expect(find.text('Share Verse'), findsOneWidget);

    await tapAndWait(tester, 'Save');
    expect(shareService.calls, ['save']);
    expect(find.text('Saved to your photos'), findsOneWidget);
    // PNG signature: the preview was really captured.
    expect(shareService.lastPng!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);

    // WhatsApp not installed → falls back to the system share sheet.
    shareService.calls.clear();
    await tapAndWait(tester, 'WhatsApp');
    expect(shareService.calls, ['app:whatsapp', 'system']);

    shareService
      ..calls.clear()
      ..appInstalled = true;
    await tapAndWait(tester, 'Instagram');
    expect(shareService.calls, ['app:instagram']);

    // Let the image cache's delayed write timer finish before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('home shows the daily verse and its reflection', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('“Be still, and know that I am God.”'), findsOneWidget);
    expect(find.text('Psalm 46:10'), findsOneWidget);

    await tester.tap(find.text('A moment of reflection'));
    await tester.pumpAndSettle();
    expect(find.text('Rest in Him.'), findsOneWidget);
  });

  testWidgets('explore opens a mood and cycles its verses', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling?'), findsOneWidget);

    await tester.tap(find.text('Anxious'));
    await tester.pumpAndSettle();
    expect(find.text('Verses for Anxiety'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rest in Him.'), 200);
    expect(find.text('Rest in Him.'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Show more verses'), 200);
    await tester.tap(find.text('Show more verses'));
    await tester.pumpAndSettle();
    expect(find.text('Give Him what feels heavy.'), findsOneWidget);
  });

  testWidgets('bottom nav switches to tabs', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favourites').last);
    await tester.pumpAndSettle();
    expect(find.text('Verses you save will appear here.'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Daily Reminders'), findsOneWidget);
  });

  testWidgets(
    'Profile tab displays reminders and toggles on when permission granted',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Daily Reminders'), findsOneWidget);
      expect(find.text('Daily Verse'), findsOneWidget);
      expect(find.text('8:00 AM'), findsOneWidget);

      final switches = find.byType(Switch);
      expect(tester.widget<Switch>(switches.first).value, isFalse);

      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      expect(notificationScheduler.requestPermissionCalls, 1);
      expect(tester.widget<Switch>(switches.first).value, isTrue);
    },
  );

  testWidgets(
    'Profile tab explains how to enable notifications when permission is denied',
    (tester) async {
      notificationScheduler.permissionGranted = false;

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      expect(notificationScheduler.requestPermissionCalls, 1);
      expect(tester.widget<Switch>(switches.first).value, isFalse);

      expect(find.text('Notifications Disabled'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications are disabled'), findsOneWidget);
    },
  );

  testWidgets('Profile tab allows changing reminder time via time picker', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('8:00 AM'));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('Profile tab shows Google sign-in button in guest mode', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(find.text('SoulVerse Account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets(
    'Profile tab signs in with Google, shows profile and Free Plan, and signs out',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      // Tap Continue with Google
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Account card displays user details and subscription tier
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@gmail.com'), findsOneWidget);
      expect(find.text('Free Plan'), findsOneWidget);

      // Sign Out
      await tester.tap(find.byTooltip('Sign Out'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to sign out of SoulVerse?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      // Returns to guest mode
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(googleSignInService.signOutCalls, 1);
    },
  );

  testWidgets('saving from Home fills the heart and Undo reverts it', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsWidgets);
    expect(find.text('Saved to favourites'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('the Share screen heart saves and removes the verse', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save to favourites'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    expect(find.text('Saved to favourites'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favourites'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Save to favourites'), findsOneWidget);
    expect(find.text('Removed from favourites'), findsOneWidget);
  });

  testWidgets('favourites list shows saved verses and supports remove + undo', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favourites').last);
    await tester.pumpAndSettle();
    expect(find.text('Psalm 46:10'), findsOneWidget);
    expect(find.text('Be still, and know that I am God.'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favourites'));
    await tester.pumpAndSettle();
    expect(find.text('Verses you save will appear here.'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Psalm 46:10'), findsOneWidget);
  });

  testWidgets('tapping a favourite opens it on the Share screen', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favourites').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Psalm 46:10'));
    await tester.pumpAndSettle();
    expect(find.text('Share Verse'), findsOneWidget);
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
  });

  testWidgets('empty favourites links to Explore', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favourites').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore verses'));
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling?'), findsOneWidget);
  });

  testWidgets('home asks for the verse of the local date', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final expected =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    expect(versesApi.requestedDailyDates, [expected]);
  });

  testWidgets('home screen widgets are synced with the daily verse', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(homeWidgetService.syncedDates, ['2026-01-01']);
  });

  testWidgets('verse card fits every widget size, even for a long verse', (
    tester,
  ) async {
    const longVerse = Verse(
      id: 'rev-21-4',
      text:
          'And God shall wipe away all tears from their eyes; and there shall be '
          'no more death, neither sorrow, nor crying, neither shall there be any '
          'more pain: for the former things are passed away.',
      reference: 'Revelation 21:4',
      translation: 'KJV',
      moods: ['sad'],
      reflection: '',
    );

    for (final size in VerseWidgetSize.values) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox.fromSize(
              size: size.logicalSize,
              child: const VerseCard(
                verse: longVerse,
                template: _template,
                background: ColoredBox(color: Color(0xFF334455)),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '${size.name} overflowed');
      expect(find.text('Revelation 21:4'), findsOneWidget);
    }
  });

  test('VerseTemplate parses hex text colour', () {
    expect(_template.textColorValue.toARGB32(), 0xFFFFFFFF);
  });
}
