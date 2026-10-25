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

/// How the verse text is set apart from the background.
enum TextEffect {
  none('None'),
  soft('Soft shadow'),
  strong('Strong shadow'),
  outline('Outline');

  const TextEffect(this.label);

  final String label;
}

/// Where the verse reference (e.g. "Psalm 34:18") is shown.
enum ReferencePlacement {
  below('Below'),
  corner('Corner'),
  hidden('Off');

  const ReferencePlacement(this.label);

  final String label;
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
    this.lineHeight = 1.3,
    this.letterSpacing = 0,
    this.effect = TextEffect.soft,
    this.textPosition = Alignment.center,
    this.reference = ReferencePlacement.below,
    this.showQuotes = true,
    this.showWatermark = true,
  });

  static const topPosition = Alignment(0, -0.8);
  static const middlePosition = Alignment.center;
  static const bottomPosition = Alignment(0, 0.8);

  static const standard = VerseStyle();

  static const minTextScale = 0.6;
  static const maxTextScale = 1.6;
  static const minLineHeight = 1.0;
  static const maxLineHeight = 2.0;
  static const minLetterSpacing = -0.05;
  static const maxLetterSpacing = 0.25;

  final VerseFont font;

  /// Multiplies the automatically chosen font size.
  final double textScale;

  /// Null uses the template's text colour.
  final Color? textColor;

  final TextAlign textAlign;

  /// Line height as a multiple of the font size.
  final double lineHeight;

  /// Extra space between letters as a fraction of the font size.
  final double letterSpacing;

  final TextEffect effect;

  /// Where the verse sits in the free space of the card; set by the
  /// Top / Middle / Bottom buttons or by dragging the text.
  final Alignment textPosition;

  final ReferencePlacement reference;
  final bool showQuotes;

  /// Only applies where the card shows a watermark (the share screen).
  final bool showWatermark;

  VerseStyle copyWith({
    VerseFont? font,
    double? textScale,
    Object? textColor = _unset,
    TextAlign? textAlign,
    double? lineHeight,
    double? letterSpacing,
    TextEffect? effect,
    Alignment? textPosition,
    ReferencePlacement? reference,
    bool? showQuotes,
    bool? showWatermark,
  }) {
    return VerseStyle(
      font: font ?? this.font,
      textScale: textScale ?? this.textScale,
      textColor: identical(textColor, _unset)
          ? this.textColor
          : textColor as Color?,
      textAlign: textAlign ?? this.textAlign,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      effect: effect ?? this.effect,
      textPosition: textPosition ?? this.textPosition,
      reference: reference ?? this.reference,
      showQuotes: showQuotes ?? this.showQuotes,
      showWatermark: showWatermark ?? this.showWatermark,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VerseStyle &&
      other.font == font &&
      other.textScale == textScale &&
      other.textColor == textColor &&
      other.textAlign == textAlign &&
      other.lineHeight == lineHeight &&
      other.letterSpacing == letterSpacing &&
      other.effect == effect &&
      other.textPosition == textPosition &&
      other.reference == reference &&
      other.showQuotes == showQuotes &&
      other.showWatermark == showWatermark;

  @override
  int get hashCode => Object.hash(
    font,
    textScale,
    textColor,
    textAlign,
    lineHeight,
    letterSpacing,
    effect,
    textPosition,
    reference,
    showQuotes,
    showWatermark,
  );
}
