import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<DailyVerse> getDailyVerse() async => const DailyVerse(
    date: '2026-01-01',
    verse: _stillVerse,
    template: _template,
  );

  @override
  Future<List<VerseTemplate>> getTemplates({String? mood}) async => const [
    _template,
  ];
}

void main() {
  Widget app() => ProviderScope(
    overrides: [versesApiProvider.overrideWithValue(_FakeVersesApi())],
    child: const SoulVerseApp(),
  );

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

  testWidgets('bottom nav switches to placeholder tabs', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favourites').last);
    await tester.pumpAndSettle();
    expect(find.text('Verses you save will appear here.'), findsOneWidget);
  });

  test('VerseTemplate parses hex text colour', () {
    expect(_template.textColorValue.toARGB32(), 0xFFFFFFFF);
  });
}
