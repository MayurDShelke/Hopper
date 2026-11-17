import 'package:flutter/material.dart';

/// Design tokens matching Hopper UI/UX specifications.
class AppTokens {
  AppTokens._();

  // Dark palette
  static const Color background = Color(0xFF0E1116);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF1F242C);
  static const Color border = Color(0xFF252C36);
  static const Color text = Color(0xFFE6EAF0);
  static const Color textMuted = Color(0xFF8B95A5);

  // Status & Brand accents
  static const Color accent = Color(0xFF2DD4BF); // Teal
  static const Color accentHover = Color(0xFF14B8A6);
  static const Color success = Color(0xFF34D399); // Green
  static const Color warning = Color(0xFFF5B83D); // Amber
  static const Color error = Color(0xFFF26D6D);   // Red
  static const Color info = Color(0xFF60A5FA);    // Blue

  // Geometry
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;

  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Typography
  static const String fontUi = 'Inter';
  static const String fontMono = 'JetBrains Mono';
}
