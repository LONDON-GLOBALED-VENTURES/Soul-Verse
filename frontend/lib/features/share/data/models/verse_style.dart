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

/// Colour treatments for the background photo.
enum BackgroundFilter {
  none('Original'),
  warm('Warm', [
    1.1, 0, 0, 0, 12, //
    0, 1.02, 0, 0, 4,
    0, 0, 0.86, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  cool('Cool', [
    0.9, 0, 0, 0, 0, //
    0, 1, 0, 0, 4,
    0, 0, 1.12, 0, 14,
    0, 0, 0, 1, 0,
  ]),
  mono('B&W', [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  // Lower contrast, lifted shadows and a little less colour.
  faded('Faded', [
    0.75, 0.08, 0.02, 0, 34, //
    0.05, 0.78, 0.02, 0, 32,
    0.05, 0.08, 0.72, 0, 36,
    0, 0, 0, 1, 0,
  ]);

  const BackgroundFilter(this.label, [this.matrix]);

  final String label;

  /// A 5x4 colour matrix; null leaves the photo unchanged.
  final List<double>? matrix;

  ColorFilter? get colorFilter =>
      matrix == null ? null : ColorFilter.matrix(matrix!);
}

/// A background chosen in the editor instead of the template's photo.
@immutable
sealed class CustomBackground {
  const CustomBackground();

  /// Rough brightness from 0 (black) to 1 (white), for picking readable text.
  double get luminance;
}

/// A photo from the user's gallery.
class PhotoBackground extends CustomBackground {
  const PhotoBackground(this.path);

  final String path;

  // Unknown without decoding the photo; treat it like the templates.
  @override
  double get luminance => 0;

  @override
  bool operator ==(Object other) =>
      other is PhotoBackground && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

class ColourBackground extends CustomBackground {
  const ColourBackground(this.color);

  final Color color;

  @override
  double get luminance => color.computeLuminance();

  @override
  bool operator ==(Object other) =>
      other is ColourBackground && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// A top-to-bottom gradient.
class GradientBackground extends CustomBackground {
  const GradientBackground(this.colors);

  final List<Color> colors;

  @override
  double get luminance =>
      colors.map((c) => c.computeLuminance()).reduce((a, b) => a + b) /
      colors.length;

  @override
  bool operator ==(Object other) =>
      other is GradientBackground && listEquals(other.colors, colors);

  @override
  int get hashCode => Object.hashAll(colors);
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
    this.overlayDarkness,
    this.blur = 0,
    this.filter = BackgroundFilter.none,
    this.customBackground,
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
  static const maxOverlayDarkness = 0.8;
  static const maxBlur = 12.0;

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

  /// How dark the overlay on the photo is; null uses the template's own.
  final double? overlayDarkness;

  /// Blur radius applied to the background photo.
  final double blur;

  final BackgroundFilter filter;

  /// Replaces the template's photo; null shows the template.
  final CustomBackground? customBackground;

  /// The overlay darkness actually used. Plain colours and gradients start
  /// with no overlay so they keep their colour; photos use the template's.
  double effectiveDarkness(double templateDarkness) =>
      overlayDarkness ??
      switch (customBackground) {
        ColourBackground() || GradientBackground() => 0,
        _ => templateDarkness,
      };

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
    Object? overlayDarkness = _unset,
    double? blur,
    BackgroundFilter? filter,
    Object? customBackground = _unset,
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
      overlayDarkness: identical(overlayDarkness, _unset)
          ? this.overlayDarkness
          : overlayDarkness as double?,
      blur: blur ?? this.blur,
      filter: filter ?? this.filter,
      customBackground: identical(customBackground, _unset)
          ? this.customBackground
          : customBackground as CustomBackground?,
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
      other.showWatermark == showWatermark &&
      other.overlayDarkness == overlayDarkness &&
      other.blur == blur &&
      other.filter == filter &&
      other.customBackground == customBackground;

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
    overlayDarkness,
    blur,
    filter,
    customBackground,
  );
}
