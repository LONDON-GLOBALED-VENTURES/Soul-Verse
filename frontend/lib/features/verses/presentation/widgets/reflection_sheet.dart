import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/verse.dart';

Future<void> showReflectionSheet(BuildContext context, Verse verse) {
  final textTheme = Theme.of(context).textTheme;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A moment of reflection', style: textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(verse.reference, style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(verse.reflection, style: textTheme.bodyLarge),
          ],
        ),
      ),
    ),
  );
}
