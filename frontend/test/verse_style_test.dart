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
