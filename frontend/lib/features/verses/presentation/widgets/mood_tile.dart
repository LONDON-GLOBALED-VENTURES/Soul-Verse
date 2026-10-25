import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/mood.dart';

/// An emotion: its emoji in a soft circle on a lightly tinted card.
class MoodTile extends StatelessWidget {
  const MoodTile({super.key, required this.mood, required this.onTap});

  final Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = mood.colorValue;

    return Material(
      color: Color.alphaBlend(tint.withValues(alpha: 0.35), AppColors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(color: tint.withValues(alpha: 0.9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 32),
                  semanticsLabel: '',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mood.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.serif,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
