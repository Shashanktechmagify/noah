import 'package:flutter/material.dart';

class AppColors {
  static const purpleDeep = Color(0xFF5E2CA5);
  static const purple = Color(0xFF7B35B0);
  static const magenta = Color(0xFFA81BC4);
  static const orchid = Color(0xFFBE5BC0);
  static const ink = Color(0xFF1E1B2E);
  static const muted = Color(0xFF8A8BA3);
  static const border = Color(0xFFE3E4F1);
  static const surface = Color(0xFFEEF0FA);
  static const tint = Color(0xFFEFE9F8);

  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A2DA8), Color(0xFFA43FB5), Color(0xFFC060C2)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5F2BA6), Color(0xFF8B3BB0), Color(0xFFA747B8)],
  );

  static const buttonGradient = LinearGradient(
    colors: [Color(0xFF9C14BD), Color(0xFFB21FC8)],
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.magenta,
      primary: AppColors.magenta,
    ),
    scaffoldBackgroundColor: AppColors.surface,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
