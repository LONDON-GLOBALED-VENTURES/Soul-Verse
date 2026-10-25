import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soulverse/features/share/data/models/verse_style.dart';

void main() {
  test('standard style keeps the original look', () {
    const style = VerseStyle.standard;
    expect(style.font, VerseFont.classic);
    expect(style.textScale, 1);
    expect(style.textColor, isNull);
    expect(style.textAlign, TextAlign.center);
    expect(style.lineHeight, 1.3);
    expect(style.letterSpacing, 0);
    expect(style.effect, TextEffect.soft);
    expect(style.textPosition, Alignment.center);
    expect(style.reference, ReferencePlacement.below);
    expect(style.showQuotes, isTrue);
    expect(style.overlayDarkness, isNull);
    expect(style.blur, 0);
    expect(style.filter, BackgroundFilter.none);
    expect(style.filter.colorFilter, isNull);
  });

  test('every filter except Original changes the colours', () {
    for (final filter in BackgroundFilter.values) {
      if (filter == BackgroundFilter.none) continue;
      expect(filter.matrix, hasLength(20), reason: filter.name);
    }
  });

  test('copyWith changes only what is given and can clear the colour', () {
    final edited = VerseStyle.standard.copyWith(
      font: VerseFont.script,
      textColor: const Color(0xFFE6C27A),
    );
    expect(edited.font, VerseFont.script);
    expect(edited.textColor, const Color(0xFFE6C27A));
    expect(edited.textAlign, TextAlign.center);

    expect(edited.copyWith(textScale: 1.2).textColor, edited.textColor);
    expect(edited.copyWith(textColor: null).textColor, isNull);
  });

  test('plain colours and gradients start without the photo overlay', () {
    expect(VerseStyle.standard.effectiveDarkness(0.35), 0.35);
    expect(
      const VerseStyle(customBackground: PhotoBackground('/a.jpg'))
          .effectiveDarkness(0.35),
      0.35,
    );
    expect(
      const VerseStyle(customBackground: ColourBackground(Color(0xFFD5E1C8)))
          .effectiveDarkness(0.35),
      0,
    );
    // Once the user moves the slider, their value wins.
    expect(
      const VerseStyle(
        customBackground: GradientBackground([Color(0xFF000000)]),
        overlayDarkness: 0.5,
      ).effectiveDarkness(0.35),
      0.5,
    );
  });

  test('backgrounds compare by value', () {
    expect(
      const GradientBackground([Color(0xFF111111), Color(0xFF222222)]),
      GradientBackground(const [Color(0xFF111111), Color(0xFF222222)]),
    );
    expect(const ColourBackground(Color(0xFFFFFFFF)).luminance, 1);
    expect(
      VerseStyle.standard
          .copyWith(customBackground: const PhotoBackground('/a.jpg'))
          .copyWith(customBackground: null)
          .customBackground,
      isNull,
    );
  });

  test('toggling a word highlights it, then removes it', () {
    final once = VerseStyle.standard.toggleHighlight(2);
    expect(once.highlightedWords, {2});
    expect(once.toggleHighlight(4).highlightedWords, {2, 4});
    expect(once.toggleHighlight(2).highlightedWords, isEmpty);
    // Sets compare by contents, so order doesn't matter.
    expect(
      VerseStyle.standard.toggleHighlight(1).toggleHighlight(3),
      VerseStyle.standard.toggleHighlight(3).toggleHighlight(1),
    );
    expect(
      once.copyWith(highlightColor: null).highlightColor,
      isNull,
      reason: 'no colour keeps the text colour',
    );
  });

  test('a style survives being saved and loaded', () {
    const styles = [
      VerseStyle(
        font: VerseFont.handwritten,
        textScale: 1.3,
        textColor: Color(0xFF3A3A3A),
        textAlign: TextAlign.right,
        lineHeight: 1.7,
        letterSpacing: 0.1,
        effect: TextEffect.outline,
        textPosition: Alignment(0.2, -0.6),
        reference: ReferencePlacement.corner,
        showQuotes: false,
        overlayDarkness: 0.5,
        blur: 4,
        filter: BackgroundFilter.faded,
        customBackground: GradientBackground([
          Color(0xFF0F2027),
          Color(0xFF2C5364),
        ]),
        highlightBold: false,
        highlightColor: null,
      ),
      VerseStyle(customBackground: PhotoBackground('/photos/a.jpg')),
      VerseStyle(customBackground: ColourBackground(Color(0xFFD5E1C8))),
      VerseStyle.standard,
    ];
    for (final style in styles) {
      expect(VerseStyle.fromJson(style.toJson()), style);
    }
  });

  test('damaged saved values fall back to the defaults', () {
    final style = VerseStyle.fromJson({
      'font': 'comic-sans',
      'textScale': 99,
      'textPosition': 'middle',
      'effect': 42,
      'customBackground': {
        'type': 'gradient',
        'colors': [1],
      },
    });
    expect(style.font, VerseFont.classic);
    expect(style.textScale, VerseStyle.maxTextScale);
    expect(style.textPosition, Alignment.center);
    expect(style.effect, TextEffect.soft);
    expect(style.customBackground, isNull, reason: 'one colour is no gradient');
    expect(style.highlightColor, VerseStyle.defaultHighlightColor);
  });

  test('next time keeps the look but not highlights or the note', () {
    final style = VerseStyle.standard
        .copyWith(font: VerseFont.bold, note: 'For Mum')
        .toggleHighlight(1);
    final next = style.forNextTime();
    expect(next.font, VerseFont.bold);
    expect(next.highlightedWords, isEmpty);
    expect(next.note, isEmpty);
  });

  test('styles with the same values are equal', () {
    expect(
      VerseStyle.standard.copyWith(textAlign: TextAlign.left),
      const VerseStyle(textAlign: TextAlign.left),
    );
    expect(
      VerseStyle.standard,
      isNot(VerseStyle.standard.copyWith(font: VerseFont.bold)),
    );
  });
}
