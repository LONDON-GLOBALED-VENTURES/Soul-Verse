import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White rounded button with a trailing chevron, e.g. "A moment of reflection  >".
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
