import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:soulverse/core/network/retry_policy.dart';
import 'package:soulverse/core/widgets/verse_card.dart';
import 'package:soulverse/features/auth/application/auth_service.dart';
import 'package:soulverse/features/auth/data/auth_api.dart';
import 'package:soulverse/features/auth/data/models/user.dart';
import 'package:soulverse/features/home_widget/home_widget_service.dart';
import 'package:soulverse/features/prayers/data/models/prayer.dart';
import 'package:soulverse/features/prayers/data/prayers_api.dart';
import 'package:soulverse/features/prayers/presentation/widgets/prayer_card.dart';
import 'package:soulverse/features/reminders/data/notification_scheduler.dart';
import 'package:soulverse/features/share/data/models/verse_style.dart';
import 'package:soulverse/features/share/data/photo_picker.dart';
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
  /// When set, the daily verse request fails with this HTTP status.
  int? dailyStatusCode;
  Verse dailyVerse = _stillVerse;
  final requestedDailyDates = <String?>[];

  @override
  Future<List<Mood>> getMoods() async => const [
    Mood(
      id: 'anxious',
      name: 'Anxious',
      title: 'Verses for Anxiety',
      emoji: '🌧️',
      color: '#C9D6DF',
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
    if (dailyStatusCode != null) {
      final request = RequestOptions(path: '/verses/daily');
      throw DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: dailyStatusCode,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return DailyVerse(
      date: '2026-01-01',
      verse: dailyVerse,
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

  bool exactAllowed = true;
  bool grantExactInSettings = false;
  var openExactSettingsCalls = 0;
  var cancelAllCalls = 0;

  @override
  Future<bool> canScheduleExactAlarms() async => exactAllowed;

  @override
  Future<bool> openExactAlarmSettings() async {
    openExactSettingsCalls++;
    if (grantExactInSettings) exactAllowed = true;
    return exactAllowed;
  }

  @override
  Future<void> cancelAll() async => cancelAllCalls++;

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

class _FakePhotoPicker implements PhotoPicker {
  String? path = '/fake/photo.jpg';

  @override
  Future<String?> pickFromGallery() async => path;
}

Prayer _prayer(String id, String author, {bool mine = false}) =>
    Prayer.fromJson({
      'id': id,
      'authorName': author,
      'title': '$author needs prayer',
      'content': 'Please pray for strength this week.',
      'isMine': mine,
    });

class _FakePrayersApi implements PrayersApi {
  List<Prayer> prayers = [
    _prayer('p_grace', 'Grace'),
    _prayer('p_mine', 'John Doe', mine: true),
  ];
  final blocked = <BlockedUser>[];
  final reports = <(String, ReportReason, String)>[];
  var createCalls = 0;

  @override
  Future<List<Prayer>> getPrayers({
    String sort = 'recent',
    String category = 'All',
    String type = 'all',
    bool mine = false,
    int page = 1,
    int limit = 50,
  }) async => page == 1 ? List.of(prayers) : [];

  @override
  Future<Prayer> createPrayer({
    required String title,
    required String content,
    String category = 'General',
    String type = 'request',
    bool isAnonymous = false,
  }) async {
    createCalls++;
    return _prayer('p_new', 'John Doe', mine: true);
  }

  @override
  Future<Map<String, dynamic>> toggleLike(String prayerId) async => {};

  @override
  Future<void> deletePrayer(String prayerId) async =>
      prayers.removeWhere((p) => p.id == prayerId);

  @override
  Future<void> reportPrayer(
    String prayerId, {
    required ReportReason reason,
    String details = '',
  }) async => reports.add((prayerId, reason, details));

  @override
  Future<void> blockAuthor(String prayerId) async {
    final author = prayers.firstWhere((p) => p.id == prayerId).authorName;
    blocked.add(
      BlockedUser(
        userId: 'usr_$author',
        name: author,
        blockedAt: DateTime(2026),
      ),
    );
    prayers.removeWhere((p) => p.authorName == author);
  }

  @override
  Future<List<BlockedUser>> getBlockedUsers() async => List.of(blocked);

  @override
  Future<void> unblockUser(String userId) async =>
      blocked.removeWhere((b) => b.userId == userId);
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

  var disconnectCalls = 0;

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
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

  var deleteAccountCalls = 0;

  /// When set, deleting the account fails with this error.
  Object? deleteAccountError;

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalls++;
    if (deleteAccountError != null) throw deleteAccountError!;
  }
}

void main() {
  late _FakeShareService shareService;
  late _FakePhotoPicker photoPicker;
  late _FakePrayersApi prayersApi;
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
    photoPicker = _FakePhotoPicker();
    prayersApi = _FakePrayersApi();
    homeWidgetService = _FakeHomeWidgetService();
    versesApi = _FakeVersesApi();
    notificationScheduler = _NoopScheduler();
    googleSignInService = _FakeGoogleSignInService();
    authApi = _FakeAuthApi();
  });

  Widget app() => ProviderScope(
    retry: appRetry,
    overrides: [
      versesApiProvider.overrideWithValue(versesApi),
      shareServiceProvider.overrideWithValue(shareService),
      photoPickerProvider.overrideWithValue(photoPicker),
      prayersApiProvider.overrideWithValue(prayersApi),
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

  // Capturing the preview is covered by the share screen test above; a second
  // capture in this file hangs on the image cache the first one leaves behind.
  testWidgets('share editor restyles the verse text and keeps earlier edits', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    VerseStyle previewStyle() =>
        tester.widget<VerseCard>(find.byType(VerseCard)).style;
    expect(previewStyle(), VerseStyle.standard);

    await tester.tap(find.text('Font'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Script font'));
    await tester.pumpAndSettle();
    expect(previewStyle().font, VerseFont.script);

    await tester.tap(find.text('Colour'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Gold text'));
    await tester.pumpAndSettle();
    expect(previewStyle().textColor, const Color(0xFFE6C27A));

    await tester.tap(find.text('Align'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.format_align_left));
    await tester.pumpAndSettle();
    expect(previewStyle().textAlign, TextAlign.left);

    await tester.tap(find.text('Size'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(previewStyle().textScale, greaterThan(1));
    // Earlier edits are kept while using another tool.
    expect(previewStyle().font, VerseFont.script);
    expect(previewStyle().textColor, const Color(0xFFE6C27A));

    Future<void> openTool(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await openTool('Spacing');
    await tester.drag(find.byType(Slider).first, const Offset(150, 0));
    await tester.drag(find.byType(Slider).last, const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(previewStyle().lineHeight, greaterThan(1.3));
    expect(previewStyle().letterSpacing, greaterThan(0));

    await openTool('Effect');
    await tester.tap(find.text('Outline'));
    await tester.pumpAndSettle();
    expect(previewStyle().effect, TextEffect.outline);
    // The outline is a stroked copy of the verse drawn under the filled one.
    final verseTexts = find.descendant(
      of: find.byType(VerseCard),
      matching: find.textContaining('Be still'),
    );
    expect(verseTexts, findsNWidgets(2));
    expect(
      tester.widget<Text>(verseTexts.first).style!.foreground!.style,
      PaintingStyle.stroke,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('share editor positions the verse and toggles its details', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    VerseStyle previewStyle() =>
        tester.widget<VerseCard>(find.byType(VerseCard)).style;
    Finder inCard(Finder finder) =>
        find.descendant(of: find.byType(VerseCard), matching: finder);
    Future<void> openTool(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await openTool('Position');
    await tester.tap(find.text('Top'));
    await tester.pumpAndSettle();
    expect(previewStyle().textPosition, VerseStyle.topPosition);
    // Dragging the verse down moves it towards the bottom.
    await tester.drag(
      inCard(find.textContaining('Be still')),
      const Offset(0, 80),
    );
    await tester.pumpAndSettle();
    expect(previewStyle().textPosition.y, greaterThan(-0.8));

    await openTool('Details');
    await tester.tap(find.text('Quote marks'));
    await tester.pumpAndSettle();
    expect(
      inCard(find.text('Be still, and know that I am God.')),
      findsWidgets,
    );
    // Shared images carry no SoulVerse watermark.
    expect(inCard(find.text('SoulVerse')), findsNothing);
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(previewStyle().reference, ReferencePlacement.hidden);
    expect(inCard(find.text('Psalm 46:10')), findsNothing);
    await tester.tap(find.text('Corner'));
    await tester.pumpAndSettle();
    expect(inCard(find.text('Psalm 46:10')), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('share editor darkens, blurs and filters the background', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    VerseStyle previewStyle() =>
        tester.widget<VerseCard>(find.byType(VerseCard)).style;
    Finder inCard(Finder finder) =>
        find.descendant(of: find.byType(VerseCard), matching: finder);
    // An unedited card has no extra layers.
    expect(inCard(find.byType(ColorFiltered)), findsNothing);
    expect(inCard(find.byType(ImageFiltered)), findsNothing);

    await tester.tap(find.text('Adjust'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider).first, const Offset(150, 0));
    await tester.drag(find.byType(Slider).last, const Offset(150, 0));
    await tester.pumpAndSettle();
    // The template starts at 0.3; dragging right darkens it.
    expect(previewStyle().overlayDarkness, greaterThan(0.3));
    expect(previewStyle().blur, greaterThan(0));
    expect(inCard(find.byType(ImageFiltered)), findsOneWidget);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('B&W filter'));
    await tester.pumpAndSettle();
    expect(previewStyle().filter, BackgroundFilter.mono);
    expect(inCard(find.byType(ColorFiltered)), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('share editor uses your photo, plain colours and gradients', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    VerseStyle previewStyle() =>
        tester.widget<VerseCard>(find.byType(VerseCard)).style;
    // The background row is the first sideways list (the tool strip is below it).
    final backgroundRow = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        )
        .first;
    Future<void> tapTile(String label) async {
      await tester.scrollUntilVisible(
        find.bySemanticsLabel(label),
        100,
        scrollable: backgroundRow,
      );
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
    }

    // Cancelling the gallery leaves the background as it was.
    photoPicker.path = null;
    await tapTile('Your photo');
    expect(previewStyle().customBackground, isNull);

    photoPicker.path = '/fake/photo.jpg';
    await tapTile('Your photo');
    expect(
      previewStyle().customBackground,
      const PhotoBackground('/fake/photo.jpg'),
    );

    // A light colour switches the white text to a dark one…
    await tapTile('Sage background');
    expect(
      previewStyle().customBackground,
      const ColourBackground(Color(0xFFD5E1C8)),
    );
    expect(previewStyle().textColor, isNotNull);
    expect(previewStyle().textColor!.computeLuminance(), lessThan(0.5));

    // …and a dark gradient switches it back.
    await tapTile('Night gradient');
    expect(previewStyle().customBackground, isA<GradientBackground>());
    expect(previewStyle().textColor, isNull);

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Background dawn'),
      -100,
      scrollable: backgroundRow,
    );
    await tester.tap(find.bySemanticsLabel('Background dawn'));
    await tester.pumpAndSettle();
    expect(previewStyle().customBackground, isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('share editor highlights tapped words and adds a note', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    VerseStyle previewStyle() =>
        tester.widget<VerseCard>(find.byType(VerseCard)).style;
    Finder inCard(Finder finder) =>
        find.descendant(of: find.byType(VerseCard), matching: finder);
    Future<void> openTool(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    final verse = inCard(find.textContaining('Be still'));
    // Outside the Highlight tool, tapping the verse does nothing.
    await tester.tap(verse);
    await tester.pumpAndSettle();
    expect(previewStyle().highlightedWords, isEmpty);

    await openTool('Highlight');
    await tester.tap(verse);
    await tester.pumpAndSettle();
    expect(previewStyle().highlightedWords, hasLength(1));
    // The tapped word is drawn bold in its own span.
    final spans = (tester.widget<Text>(verse).textSpan! as TextSpan).children!;
    expect(
      spans.where((s) => s.style?.fontWeight == FontWeight.w700),
      hasLength(1),
    );

    // Tapping the same word again removes it.
    await tester.tap(verse);
    await tester.pumpAndSettle();
    expect(previewStyle().highlightedWords, isEmpty);

    await tester.tap(verse);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(previewStyle().highlightedWords, isEmpty);

    await openTool('Note');
    await tester.enterText(find.byType(TextField), 'For Mum');
    await tester.pumpAndSettle();
    expect(previewStyle().note, 'For Mum');
    expect(inCard(find.text('For Mum')), findsOneWidget);
    await tester.tap(find.byTooltip('Remove note'));
    await tester.pumpAndSettle();
    expect(inCard(find.text('For Mum')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('share editor undoes, redoes and resets edits', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    VerseStyle previewStyle() =>
        tester.widget<VerseCard>(find.byType(VerseCard)).style;
    bool enabled(String tooltip) =>
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip(tooltip),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed !=
        null;
    Future<void> tapAndSettle(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    expect(enabled('Undo'), isFalse);
    expect(enabled('Redo'), isFalse);

    await tapAndSettle(find.text('Font'));
    await tapAndSettle(find.bySemanticsLabel('Script font'));
    await tapAndSettle(find.text('Size'));
    // A whole slider drag is a single undo step.
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(previewStyle().textScale, greaterThan(1));

    await tapAndSettle(find.byTooltip('Undo'));
    expect(previewStyle().textScale, 1);
    expect(previewStyle().font, VerseFont.script);
    await tapAndSettle(find.byTooltip('Undo'));
    expect(previewStyle(), VerseStyle.standard);
    expect(enabled('Undo'), isFalse);

    await tapAndSettle(find.byTooltip('Redo'));
    expect(previewStyle().font, VerseFont.script);
    await tapAndSettle(find.byTooltip('Redo'));
    expect(previewStyle().textScale, greaterThan(1));
    expect(enabled('Redo'), isFalse);

    await tapAndSettle(find.text('Reset'));
    expect(previewStyle(), VerseStyle.standard);
    // Reset can be undone too.
    await tapAndSettle(find.byTooltip('Undo'));
    expect(previewStyle().font, VerseFont.script);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('share editor remembers the last style for the next verse', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    VerseStyle previewStyle() =>
        tester.widget<VerseCard>(find.byType(VerseCard)).style;

    await tester.tap(find.text('Font'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Bold font'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'For Mum');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();

    expect(previewStyle().font, VerseFont.bold);
    // The note was for that one image.
    expect(previewStyle().note, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('home hides "A moment of reflection" when there is none', (
    tester,
  ) async {
    versesApi.dailyVerse = const Verse(
      id: 'john-11-35',
      text: 'Jesus wept.',
      reference: 'John 11:35',
      translation: 'WEB',
      moods: ['heartbroken'],
      reflection: '',
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('“Jesus wept.”'), findsOneWidget);
    expect(find.text('A moment of reflection'), findsNothing);
  });

  testWidgets('home explains when there are no verses yet', (tester) async {
    versesApi.dailyStatusCode = 404;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('No verses yet'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(versesApi.requestedDailyDates, hasLength(1), reason: 'no retries');
  });

  testWidgets('home still offers retry when loading genuinely fails', (
    tester,
  ) async {
    versesApi.dailyStatusCode = 500;
    await tester.pumpWidget(app());
    // Server errors are retried with backoff first; let those play out.
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();

    expect(versesApi.requestedDailyDates.length, greaterThan(1));
    expect(find.text('We couldn\'t load today\'s verse.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No verses yet'), findsNothing);
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
    expect(find.text('🌧️'), findsOneWidget, reason: 'tiles show the emoji');

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

  group('exact alarm prompt', () {
    final card = find.text('Get your verse right on time');

    Future<void> openProfileWithReminderOn(WidgetTester tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
    }

    testWidgets('appears when reminders are on but exact alarms are off', (
      tester,
    ) async {
      notificationScheduler.exactAllowed = false;
      await openProfileWithReminderOn(tester);

      expect(card, findsOneWidget);
    });

    testWidgets('stays hidden when exact alarms are allowed', (tester) async {
      await openProfileWithReminderOn(tester);

      expect(card, findsNothing);
    });

    testWidgets('stays hidden while reminders are off', (tester) async {
      notificationScheduler.exactAllowed = false;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      expect(card, findsNothing);
    });

    testWidgets('Allow opens settings; granting hides it and reschedules', (
      tester,
    ) async {
      notificationScheduler
        ..exactAllowed = false
        ..grantExactInSettings = true;
      await openProfileWithReminderOn(tester);
      final reschedulesBefore = notificationScheduler.cancelAllCalls;

      await tester.ensureVisible(find.text('Allow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(notificationScheduler.openExactSettingsCalls, 1);
      expect(card, findsNothing);
      expect(
        notificationScheduler.cancelAllCalls,
        greaterThan(reschedulesBefore),
        reason: 'reminders rescheduled as exact',
      );
    });

    testWidgets('declining in settings keeps the prompt', (tester) async {
      notificationScheduler.exactAllowed = false;
      await openProfileWithReminderOn(tester);

      await tester.ensureVisible(find.text('Allow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(notificationScheduler.openExactSettingsCalls, 1);
      expect(card, findsOneWidget);
    });
  });

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

  Future<void> signInFromProfile(WidgetTester tester) async {
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteAccount(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'deleting the account signs out and clears that account from the phone',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await signInFromProfile(tester);
      final userId = authApi.currentUser.id;
      final prefs = SharedPreferencesAsync();
      await tester.runAsync(
        () => prefs.setString('favourites_$userId', '{"items":[]}'),
      );

      await tapDeleteAccount(tester);
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('doesn\'t cancel a subscription'), findsOne);

      // Cancelling changes nothing.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(authApi.deleteAccountCalls, 0);
      expect(find.text('John Doe'), findsOneWidget);

      await tapDeleteAccount(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();

      expect(authApi.deleteAccountCalls, 1);
      expect(googleSignInService.disconnectCalls, 1);
      expect(find.text('Your account has been deleted'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        await tester.runAsync(() => prefs.getString('favourites_$userId')),
        isNull,
      );
    },
  );

  testWidgets('if deleting fails, the user stays signed in and can retry', (
    tester,
  ) async {
    authApi.deleteAccountError = DioException(
      requestOptions: RequestOptions(path: '/auth/me'),
      type: DioExceptionType.connectionError,
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await signInFromProfile(tester);

    await tapDeleteAccount(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t delete your account'), findsOneWidget);
    expect(googleSignInService.disconnectCalls, 0);

    // The connection is back; trying again works.
    authApi.deleteAccountError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(authApi.deleteAccountCalls, 2);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  Future<void> openPrayers(WidgetTester tester) async {
    // Taller than the default, so both cards fit above the Share Prayer button.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prayers').last);
    await tester.pumpAndSettle();
  }

  Future<void> openMenuOf(WidgetTester tester, String title) async {
    final card = find.ancestor(
      of: find.text(title),
      matching: find.byType(PrayerCard),
    );
    await tester.tap(
      find.descendant(of: card, matching: find.byTooltip('More options')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prayer menus: others get Report and Block, yours get Delete', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openPrayers(tester);

    await openMenuOf(tester, 'Grace needs prayer');
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await openMenuOf(tester, 'John Doe needs prayer');
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('guests are asked to sign in before reporting', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openPrayers(tester);

    await openMenuOf(tester, 'Grace needs prayer');
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Report a prayer'), findsOneWidget);
    expect(find.text('Report this prayer'), findsNothing);
    expect(prayersApi.reports, isEmpty);
  });

  testWidgets('reporting sends the reason and removes the prayer', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await signInFromProfile(tester);
    await openPrayers(tester);

    await openMenuOf(tester, 'Grace needs prayer');
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Report this prayer'), findsOneWidget);
    // A reason is required.
    final reportButton = find.widgetWithText(FilledButton, 'Report');
    expect(tester.widget<FilledButton>(reportButton).onPressed, isNull);

    await tester.tap(find.text(ReportReason.spam.label));
    await tester.enterText(find.byType(TextField), 'Selling things');
    await tester.pumpAndSettle();
    await tester.tap(reportButton);
    await tester.pumpAndSettle();

    expect(prayersApi.reports, [
      ('p_grace', ReportReason.spam, 'Selling things'),
    ]);
    expect(find.text('Grace needs prayer'), findsNothing);
    expect(
      find.text('Thanks for reporting. Our team will review it.'),
      findsOne,
    );
  });

  testWidgets('blocking hides their prayers; Profile lists them to unblock', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await signInFromProfile(tester);
    await openPrayers(tester);

    await openMenuOf(tester, 'Grace needs prayer');
    await tester.tap(find.text('Block user'));
    await tester.pumpAndSettle();
    expect(find.text('Block Grace?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Block'));
    await tester.pumpAndSettle();

    expect(find.text('Grace needs prayer'), findsNothing);
    expect(find.text('Grace is blocked.'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Blocked users'));
    await tester.tap(find.text('Blocked users'));
    await tester.pumpAndSettle();
    expect(find.text('Grace'), findsOneWidget);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(prayersApi.blocked, isEmpty);
    expect(find.text('No one is blocked'), findsOneWidget);
  });

  testWidgets(
    'the community guidelines are agreed to once, before the first post',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await signInFromProfile(tester);
      await openPrayers(tester);

      await tester.tap(find.text('Share Prayer'));
      await tester.pumpAndSettle();
      expect(find.text('Community guidelines'), findsOneWidget);
      // Cancelling means no post.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Post Anonymously'), findsNothing);

      await tester.tap(find.text('Share Prayer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I agree'));
      await tester.pumpAndSettle();
      expect(find.text('Post Anonymously'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Agreed once: straight to the form next time.
      await tester.tap(find.text('Share Prayer'));
      await tester.pumpAndSettle();
      expect(find.text('Community guidelines'), findsNothing);
      expect(find.text('Post Anonymously'), findsOneWidget);
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
