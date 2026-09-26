import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppFonts {
  static const serif = 'PlayfairDisplay';
  static const sans = 'Inter';
}

abstract final class AppRadius {
  static const card = 20.0;
  static const tile = 16.0;
}

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.textPrimary,
      onPrimary: AppColors.surface,
      secondary: AppColors.accent,
      onSecondary: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
    );

    const serif = TextStyle(
      fontFamily: AppFonts.serif,
      color: AppColors.textPrimary,
    );
    const sans = TextStyle(
      fontFamily: AppFonts.sans,
      color: AppColors.textPrimary,
    );

    final textTheme = TextTheme(
      displaySmall: serif.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      headlineMedium: serif.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineSmall: serif.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: serif.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: sans.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: sans.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: sans.copyWith(
        fontSize: 14,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      bodySmall: sans.copyWith(fontSize: 12, color: AppColors.textSecondary),
      labelLarge: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: sans.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: sans.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.sans,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 68,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.surface,
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }
}
