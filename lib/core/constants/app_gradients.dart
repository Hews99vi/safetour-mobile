import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.midnight,
      AppColors.deepSpace,
      Color(0xFF0F172A),
    ],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.neonCyan,
      AppColors.neonViolet,
    ],
  );

  static const LinearGradient alert = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.danger,
      Color(0xFFFF7A7A),
    ],
  );
}
