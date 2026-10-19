import 'package:flutter/material.dart';

/// UI/UX V1.0 Design Tokens。所有页面统一从这里取色，避免散落硬编码。
abstract final class AppColors {
  static const background = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFEFA);
  static const avatarStage = Color(0xFFEADFD3);
  static const primary = Color(0xFFBB7066);
  static const primaryActive = Color(0xFF9D524B);
  static const textPrimary = Color(0xFF292723);
  static const textSecondary = Color(0xFF8F887F);
  static const border = Color(0xFFE9E2D8);
  static const success = Color(0xFF618575);
  static const warning = Color(0xFFB9834B);
}

abstract final class AppSpacing {
  static const double page = 20;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class AppRadius {
  static const double card = 18;
  static const double avatar = 26;
  static const double pill = 50;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outlineVariant: AppColors.border,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(fontSize: 13),
      shape: const StadiumBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, color: AppColors.textPrimary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
  );
}
