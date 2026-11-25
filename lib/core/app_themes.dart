import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',

    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      secondary: AppColors.secondaryAccent,
      onSecondary: Colors.white,
      surface: AppColors.background,
      surfaceContainer: AppColors.cardBg,
      surfaceContainerHigh: AppColors.elevatedBg,
      onSurface: AppColors.textMainColor,
      outline: AppColors.border,
      error: AppColors.error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textMainColor,
      elevation: 0,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.elevatedBg,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
