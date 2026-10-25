import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/share/data/models/verse_style.dart';
import '../../features/verses/data/models/verse.dart';
import '../../features/verses/data/models/verse_template.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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
  });

  final Verse verse;
  final VerseTemplate template;
  final BorderRadius borderRadius;
  final bool showWatermark;

  /// The user's edits from the share screen; [VerseStyle.standard] elsewhere.
  final VerseStyle style;

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

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          background ??
              CachedNetworkImage(
                imageUrl: template.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.placeholder),
                errorWidget: (_, _, _) =>
                    const ColoredBox(color: AppColors.placeholder),
              ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: template.overlayOpacity * 0.6),
                  Colors.black.withValues(alpha: template.overlayOpacity),
                  Colors.black.withValues(alpha: template.overlayOpacity * 1.4),
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
                ),
              ),
              ?footer,
            ],
          ),
          if (showWatermark)
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

class _VerseText extends StatelessWidget {
  const _VerseText({
    required this.verse,
    required this.style,
    required this.textColor,
  });

  final Verse verse;
  final VerseStyle style;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
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

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: math.min(width, height) * 0.06,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width - hPadding * 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: switch (style.textAlign) {
                    TextAlign.left ||
                    TextAlign.start => CrossAxisAlignment.start,
                    TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
                    _ => CrossAxisAlignment.center,
                  },
                  children: [
                    _EffectText(
                      '“${verse.text}”',
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
                    ),
                    SizedBox(height: fontSize * 0.9),
                    _EffectText(
                      verse.reference,
                      // The reference never had the soft shadow; keep it that way.
                      effect: style.effect == TextEffect.soft
                          ? TextEffect.none
                          : style.effect,
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
                ),
              ),
            ),
          ),
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
  });

  final String text;
  final TextEffect effect;
  final TextAlign textAlign;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 14;
    // Light text gets a dark outline or shadow, dark text a light one.
    final contrast = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    Text styled(TextStyle s) => Text(text, textAlign: textAlign, style: s);

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
          ),
          styled(style.copyWith(color: color)),
        ],
      ),
    };
  }
}
