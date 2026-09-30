import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
  });

  final Verse verse;
  final VerseTemplate template;
  final BorderRadius borderRadius;

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
                child: _VerseText(verse: verse, template: template),
              ),
              ?footer,
            ],
          ),
        ],
      ),
    );
  }
}

class _VerseText extends StatelessWidget {
  const _VerseText({required this.verse, required this.template});

  final Verse verse;
  final VerseTemplate template;

  @override
  Widget build(BuildContext context) {
    final textColor = template.textColorValue;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final length = verse.text.length;
        // Width-based size, capped by what fits the area (matters for small/wide widgets).
        // FittedBox below is the final guard against overflow.
        final fontSize = math.min(
          width * VerseCard._fontFactor(length),
          math.sqrt(width * height * 0.5 / length),
        );
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
                  children: [
                    Text(
                      '“${verse.text}”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.serif,
                        fontSize: fontSize,
                        height: 1.3,
                        color: textColor,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black26),
                        ],
                      ),
                    ),
                    SizedBox(height: fontSize * 0.9),
                    Text(
                      verse.reference,
                      style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontSize: (fontSize * 0.45).clamp(11, 18),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: textColor.withValues(alpha: 0.9),
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
