import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
