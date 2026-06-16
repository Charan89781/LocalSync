import 'package:flutter/material.dart';

class AppColors {
  // Vibrant Blue Palette (Based on new UI)
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color secondaryBlue = Color(0xFF00C6FF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8F9FA);

  // Accents
  static const Color accentBlue = Color(0xFF007BFF);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color successGreen = Color(0xFF34C759);

  // Text
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFADB5BD);

  // Premium Dark Palette
  static const Color primaryNavy = Color(0xFF0A121A);
  static const Color secondaryNavy = Color(0xFF15202B);
  static const Color surfaceNavy = Color(0xFF1E2732);
  static const Color neonCyan = Color(0xFF00D1FF);
  static const Color neonPurple = Color(0xFF5856D6);
  static const Color neonGreen = successGreen;
  static const Color neonYellow = warningOrange;
  static const Color error = errorRed;
  static const Color warning = warningOrange;
  static const Color success = successGreen;
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassDark = Color(0xCC0A0E12);
  static const Color primary = primaryBlue;
  static const Color secondary = secondaryBlue;
  static const Color textPrimary = textDark;
  static const Color textSecondary = textGray;
  static const Color textMuted = textLight;

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primaryBlue, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = premiumGradient;

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sosGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFFF4B4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFFF9500)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient neonGradient =
      headerGradient; // Restored as alias
}
