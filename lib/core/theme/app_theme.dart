import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_text_theme.dart';

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonCyan,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.neonCyan,
      secondary: AppColors.neonViolet,
      surface: AppColors.steel,
      error: AppColors.danger,
      outline: AppColors.glassStroke,
      onPrimary: AppColors.midnight,
      onSurface: AppColors.ice,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.midnight,
      textTheme: AppTextTheme.build(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassStroke),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.midnight,
          backgroundColor: AppColors.neonCyan,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      dividerColor: AppColors.glassStroke,
      iconTheme: const IconThemeData(color: AppColors.ice),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonCyan,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.neonCyan,
      secondary: AppColors.neonViolet,
      surface: const Color(0xFFF6F7FB),
      error: AppColors.danger,
      outline: AppColors.glassStroke,
      onPrimary: AppColors.midnight,
      onSurface: const Color(0xFF111827),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      textTheme: AppTextTheme.build(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassStroke),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.midnight,
          backgroundColor: AppColors.neonCyan,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      dividerColor: AppColors.glassStroke,
      iconTheme: const IconThemeData(color: Color(0xFF111827)),
    );
  }
}
