import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;

import '../../features/share/data/models/verse_style.dart';
import '../../features/verses/data/models/verse.dart';
import '../../features/verses/data/models/verse_template.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The background before filters, blur and overlay: the user's photo, colour
/// or gradient when one is chosen, otherwise the template's photo.
Widget verseBackground(VerseTemplate template, CustomBackground? custom) {
  const placeholder = ColoredBox(color: AppColors.placeholder);
  return switch (custom) {
    PhotoBackground(:final path) => Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    ),
    ColourBackground(:final color) => ColoredBox(color: color),
    GradientBackground(:final colors) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    ),
    null => CachedNetworkImage(
      imageUrl: template.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    ),
  };
}

class VerseCard extends StatelessWidget {
  const VerseCard({
    super.key,
    required this.verse,
    required this.template,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.card)),
    this.header,
    this.footer,
    this.background,
    this.showWatermark = false,
    this.style = VerseStyle.standard,
    this.onTextPositionChanged,
    this.onWordTapped,
  });

  final Verse verse;
  final VerseTemplate template;
  final BorderRadius borderRadius;
  final bool showWatermark;

  /// The user's edits from the share screen; [VerseStyle.standard] elsewhere.
  final VerseStyle style;

  /// When set, the verse can be dragged and this reports its new position.
  final ValueChanged<Alignment>? onTextPositionChanged;

  /// When set, tapping a word of the verse reports its index (for highlighting).
  final ValueChanged<int>? onWordTapped;

  /// Replaces the network image, e.g. with an already-decoded image for offscreen rendering.
  final Widget? background;

  /// Optional content drawn on the image above / below the verse (e.g. date, actions).
  final Widget? header;
  final Widget? footer;

  // Longer verses get a smaller font so they fit the card without overflowing.
  static double _fontFactor(int length) {
    if (length < 70) return 0.085;
    if (length < 130) return 0.07;
    if (length < 190) return 0.06;
    return 0.052;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = style.textColor ?? template.textColorValue;
    final darkness = style.effectiveDarkness(template.overlayOpacity);

    Widget photo =
        background ?? verseBackground(template, style.customBackground);
    final colorFilter = style.filter.colorFilter;
    if (colorFilter != null) {
      photo = ColorFiltered(colorFilter: colorFilter, child: photo);
    }
    if (style.blur > 0) {
      // Blur pulls in empty space at the edges, leaving a pale border, so the
      // photo is drawn larger than the card and the soft edge is clipped off.
      final bleed = style.blur * 3;
      photo = Positioned(
        left: -bleed,
        top: -bleed,
        right: -bleed,
        bottom: -bleed,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: style.blur,
            sigmaY: style.blur,
            tileMode: TileMode.clamp,
          ),
          child: photo,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: darkness * 0.6),
                  Colors.black.withValues(alpha: darkness),
                  Colors.black.withValues(alpha: (darkness * 1.4).clamp(0, 1)),
                ],
              ),
            ),
          ),
          Column(
            children: [
              ?header,
              Expanded(
                child: _VerseText(
                  verse: verse,
                  style: style,
                  textColor: textColor,
                  onPositionChanged: onTextPositionChanged,
                  onWordTapped: onWordTapped,
                ),
              ),
              ?footer,
            ],
          ),
          if (style.reference == ReferencePlacement.corner)
            Positioned(
              left: 18,
              bottom: 18,
              child: _EffectText(
                verse.reference,
                effect: _referenceEffect(style.effect),
                textAlign: TextAlign.left,
                color: textColor.withValues(alpha: 0.9),
                style: const TextStyle(
                  fontFamily: AppFonts.sans,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          if (showWatermark && style.showWatermark)
            Positioned(
              right: 18,
              bottom: 18,
              child: _Watermark(textColor: textColor),
            ),
        ],
      ),
    );
  }
}

class _Watermark extends StatelessWidget {
  const _Watermark({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/app_icon_foreground.png',
          width: 15,
          height: 15,
        ),
        const SizedBox(width: 5),
        Text(
          'SoulVerse',
          style: TextStyle(
            fontFamily: AppFonts.serif,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: textColor.withValues(alpha: 0.8),
            shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
          ),
        ),
      ],
    );
  }
}

// The reference never had the soft shadow; keep it plain for that effect.
TextEffect _referenceEffect(TextEffect effect) =>
    effect == TextEffect.soft ? TextEffect.none : effect;

// Words and the spaces between them; word indexes count only the words.
final _tokens = RegExp(r'\S+|\s+');

/// The index of the word at character [offset] of [text], or null for a space.
int? _wordAtOffset(String text, int offset) {
  var word = -1;
  for (final token in _tokens.allMatches(text)) {
    final isWord = token[0]!.trim().isNotEmpty;
    if (isWord) word++;
    // A tap on the right half of a word's last letter lands just after it.
    final end = isWord ? token.end + 1 : token.end;
    if (offset >= token.start && offset < end) return isWord ? word : null;
  }
  return null;
}

RenderParagraph? _paragraphIn(RenderObject? object) {
  if (object is RenderParagraph) return object;
  RenderParagraph? found;
  object?.visitChildren((child) => found ??= _paragraphIn(child));
  return found;
}

class _VerseText extends StatefulWidget {
  const _VerseText({
    required this.verse,
    required this.style,
    required this.textColor,
    this.onPositionChanged,
    this.onWordTapped,
  });

  final Verse verse;
  final VerseStyle style;
  final Color textColor;
  final ValueChanged<Alignment>? onPositionChanged;
  final ValueChanged<int>? onWordTapped;

  @override
  State<_VerseText> createState() => _VerseTextState();
}

class _VerseTextState extends State<_VerseText> {
  // Measures the text block so a drag moves it exactly with the finger.
  final _blockKey = GlobalKey();

  // Finds which word a tap lands on.
  final _verseKey = GlobalKey();

  int? _wordAt(Offset globalPosition, String text) {
    final paragraph = _paragraphIn(
      _verseKey.currentContext?.findRenderObject(),
    );
    if (paragraph == null) return null;
    final local = paragraph.globalToLocal(globalPosition);
    if (!(Offset.zero & paragraph.size).contains(local)) return null;
    return _wordAtOffset(text, paragraph.getPositionForOffset(local).offset);
  }

  // A drag is measured from where it started; several updates can arrive
  // before the new position is rebuilt, so adding to the current one loses moves.
  Alignment _dragStart = Alignment.center;
  Offset _dragDistance = Offset.zero;

  /// Converts a drag of [delta] pixels into a new position in [area].
  Alignment _dragged(Alignment from, Offset delta, Size area) {
    final block = _blockKey.currentContext?.size ?? Size.zero;
    double move(double current, double d, double free) =>
        free < 1 ? current : (current + 2 * d / free).clamp(-1.0, 1.0);
    return Alignment(
      move(from.x, delta.dx, area.width - block.width),
      move(from.y, delta.dy, area.height - block.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verse = widget.verse;
    final style = widget.style;
    final textColor = widget.textColor;
    final font = style.font;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final length = verse.text.length;
        // Width-based size, capped by what fits the area (matters for small/wide widgets).
        // FittedBox below is the final guard against overflow.
        final fontSize =
            math.min(
              width * VerseCard._fontFactor(length),
              math.sqrt(width * height * 0.5 / length),
            ) *
            style.textScale *
            font.sizeFactor;
        final hPadding = width * 0.1;
        // The block is 80% of the width; the narrower margin leaves room to
        // drag it sideways. Centred, it lays out exactly as before.
        final hMargin = width * 0.04;
        final vMargin = math.min(width, height) * 0.06;
        final area = Size(width - hMargin * 2, height - vMargin * 2);
        final onPositionChanged = widget.onPositionChanged;
        final onWordTapped = widget.onWordTapped;
        final verseText = style.showQuotes ? '“${verse.text}”' : verse.text;
        final note = style.note.trim();

        Widget block = FittedBox(
          key: _blockKey,
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: width - hPadding * 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: switch (style.textAlign) {
                TextAlign.left || TextAlign.start => CrossAxisAlignment.start,
                TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
                _ => CrossAxisAlignment.center,
              },
              children: [
                _EffectText(
                  verseText,
                  textKey: _verseKey,
                  effect: style.effect,
                  textAlign: style.textAlign,
                  color: textColor,
                  style: TextStyle(
                    fontFamily: font.family,
                    fontVariations: font.variations,
                    fontSize: fontSize,
                    height: style.lineHeight,
                    letterSpacing: fontSize * style.letterSpacing,
                  ),
                  highlightedWords: style.highlightedWords,
                  highlightStyle: style.highlightBold
                      ? TextStyle(
                          fontWeight: FontWeight.w700,
                          fontVariations: font.weight == null
                              ? null
                              : const [FontVariation('wght', 700)],
                        )
                      : const TextStyle(),
                  highlightColor: style.highlightColor,
                ),
                if (style.reference == ReferencePlacement.below) ...[
                  SizedBox(height: fontSize * 0.9),
                  _EffectText(
                    verse.reference,
                    effect: _referenceEffect(style.effect),
                    textAlign: style.textAlign,
                    color: textColor.withValues(alpha: 0.9),
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: (fontSize * 0.45).clamp(11, 18),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
                if (note.isNotEmpty) ...[
                  SizedBox(height: fontSize * 0.7),
                  _EffectText(
                    note,
                    effect: style.effect,
                    textAlign: style.textAlign,
                    color: textColor,
                    style: TextStyle(
                      fontFamily: font.family,
                      fontVariations: font.variations,
                      fontSize: (fontSize * 0.55).clamp(12, 26),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        if (onPositionChanged != null || onWordTapped != null) {
          block = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onWordTapped == null
                ? null
                : (details) {
                    final word = _wordAt(details.globalPosition, verseText);
                    if (word != null) onWordTapped(word);
                  },
            onPanStart: onPositionChanged == null
                ? null
                : (_) {
                    _dragStart = style.textPosition;
                    _dragDistance = Offset.zero;
                  },
            onPanUpdate: onPositionChanged == null
                ? null
                : (details) {
                    _dragDistance += details.delta;
                    onPositionChanged(
                      _dragged(_dragStart, _dragDistance, area),
                    );
                  },
            child: block,
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: vMargin),
          child: Align(alignment: style.textPosition, child: block),
        );
      },
    );
  }
}

/// Text drawn with a [TextEffect]. [style] must not set a colour; [color] is
/// applied here because an outline needs a stroke paint instead.
class _EffectText extends StatelessWidget {
  const _EffectText(
    this.text, {
    required this.effect,
    required this.textAlign,
    required this.color,
    required this.style,
    this.textKey,
    this.highlightedWords = const {},
    this.highlightStyle = const TextStyle(),
    this.highlightColor,
  });

  final String text;
  final TextEffect effect;
  final TextAlign textAlign;
  final Color color;
  final TextStyle style;

  /// Put on the filled (top) text so taps can be matched to its words.
  final Key? textKey;

  final Set<int> highlightedWords;

  /// Weight for highlighted words; must not set a colour (see [highlightColor]).
  final TextStyle highlightStyle;
  final Color? highlightColor;

  /// The text split so highlighted words get their own style. The outline copy
  /// skips the colour so it stays a stroke, but keeps the weight so both line up.
  InlineSpan _span({required bool withColour}) {
    if (highlightedWords.isEmpty) return TextSpan(text: text);
    final highlight = withColour && highlightColor != null
        ? highlightStyle.copyWith(color: highlightColor)
        : highlightStyle;
    final spans = <TextSpan>[];
    var word = -1;
    for (final token in _tokens.allMatches(text)) {
      final value = token[0]!;
      final isWord = value.trim().isNotEmpty;
      if (isWord) word++;
      spans.add(
        TextSpan(
          text: value,
          style: isWord && highlightedWords.contains(word) ? highlight : null,
        ),
      );
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 14;
    // Light text gets a dark outline or shadow, dark text a light one.
    final contrast = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    Text styled(TextStyle s, {bool fill = true}) => Text.rich(
      _span(withColour: fill),
      key: fill ? textKey : null,
      textAlign: textAlign,
      style: s,
    );

    return switch (effect) {
      TextEffect.none => styled(style.copyWith(color: color)),
      TextEffect.soft => styled(
        style.copyWith(
          color: color,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black26)],
        ),
      ),
      TextEffect.strong => styled(
        style.copyWith(
          color: color,
          shadows: [
            Shadow(
              blurRadius: fontSize * 0.3,
              offset: Offset(0, fontSize * 0.04),
              color: contrast.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
      TextEffect.outline => Stack(
        children: [
          styled(
            style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.1
                ..strokeJoin = StrokeJoin.round
                ..color = contrast.withValues(alpha: 0.9),
            ),
            fill: false,
          ),
          styled(style.copyWith(color: color)),
        ],
      ),
    };
  }
}
