import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../../core/theme/app_theme.dart';

/// Fonts offered in the verse editor (all bundled in assets/fonts).
enum VerseFont {
  classic('Classic', AppFonts.serif),
  modern('Modern', AppFonts.sans),
  elegant('Elegant', 'CormorantGaramond', weight: 500, sizeFactor: 1.12),
  script('Script', 'DancingScript', weight: 500, sizeFactor: 1.08),
  handwritten('Handwritten', 'Caveat', weight: 500, sizeFactor: 1.2),
  bold('Bold', 'Oswald', weight: 500, sizeFactor: 0.95);

  const VerseFont(this.label, this.family, {this.weight, this.sizeFactor = 1});

  final String label;
  final String family;

  /// Weight-axis value for variable fonts; null for static fonts.
  final double? weight;

  /// Evens out how large different fonts look at the same font size.
  final double sizeFactor;

  List<FontVariation>? get variations =>
      weight == null ? null : [FontVariation('wght', weight!)];
}

const _unset = Object();

/// How the user has customised a verse image. [standard] matches the
/// original look, so cards that aren't edited render exactly as before.
@immutable
class VerseStyle {
  const VerseStyle({
    this.font = VerseFont.classic,
    this.textScale = 1,
    this.textColor,
    this.textAlign = TextAlign.center,
  });

  static const standard = VerseStyle();

  static const minTextScale = 0.6;
  static const maxTextScale = 1.6;

  final VerseFont font;

  /// Multiplies the automatically chosen font size.
  final double textScale;

  /// Null uses the template's text colour.
  final Color? textColor;

  final TextAlign textAlign;

  VerseStyle copyWith({
    VerseFont? font,
    double? textScale,
    Object? textColor = _unset,
    TextAlign? textAlign,
  }) {
    return VerseStyle(
      font: font ?? this.font,
      textScale: textScale ?? this.textScale,
      textColor: identical(textColor, _unset)
          ? this.textColor
          : textColor as Color?,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VerseStyle &&
      other.font == font &&
      other.textScale == textScale &&
      other.textColor == textColor &&
      other.textAlign == textAlign;

  @override
  int get hashCode => Object.hash(font, textScale, textColor, textAlign);
}
