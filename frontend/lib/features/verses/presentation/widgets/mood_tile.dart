import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/mood.dart';

class MoodTile extends StatelessWidget {
  const MoodTile({super.key, required this.mood, required this.onTap});

  final Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Material(
        color: AppColors.placeholder,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: mood.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    mood.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.serif,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
