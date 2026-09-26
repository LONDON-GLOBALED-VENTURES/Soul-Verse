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

const _verse = Verse(
  id: 'ps-46-10',
  text: 'Be still, and know that I am God.',
  reference: 'Psalm 46:10',
  translation: 'KJV',
  moods: ['stressed'],
  reflection: 'Rest in Him.',
);

const _template = VerseTemplate(
  id: 'dawn',
  imageUrl: 'http://test/dawn.png',
  moods: ['hopeful'],
  textColor: '#FFFFFF',
  overlayOpacity: 0.3,
);

class _FakeVersesApi implements VersesApi {
  @override
  Future<List<Mood>> getMoods() async => const [
    Mood(id: 'anxious', name: 'Anxious', imageUrl: 'http://test/mist.png'),
  ];

  @override
  Future<List<Verse>> getVerses({String? mood}) async => const [_verse];

  @override
  Future<DailyVerse> getDailyVerse() async =>
      const DailyVerse(date: '2026-01-01', verse: _verse, template: _template);

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

  testWidgets('home shows the daily verse', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('“Be still, and know that I am God.”'), findsOneWidget);
    expect(find.text('Psalm 46:10'), findsOneWidget);
  });

  testWidgets('bottom nav switches tabs', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling?'), findsOneWidget);

    await tester.tap(find.text('Favourites').last);
    await tester.pumpAndSettle();
    expect(find.text('Verses you save will appear here.'), findsOneWidget);
  });

  test('VerseTemplate parses hex text colour', () {
    expect(_template.textColorValue.toARGB32(), 0xFFFFFFFF);
  });
}
