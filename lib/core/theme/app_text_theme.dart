import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextTheme {
  static TextTheme build(TextTheme base) {
    final theme = GoogleFonts.spaceGroteskTextTheme(base);
    return theme.copyWith(
      displayLarge: theme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: theme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      titleMedium: theme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      bodyMedium: theme.bodyMedium?.copyWith(
        letterSpacing: 0.2,
      ),
      labelLarge: theme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
