import 'package:flutter/material.dart';

class StaffTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF0288D1);
  static const Color accentBlue = Color(0xFF03A9F4);
  static const Color successGreen = Color(0xFF43A047);
  static const Color warningOrange = Color(0xFFFB8C00);
  static const Color errorRed = Color(0xFFE53935);
  static const Color background = Color(0xFFF5F7FA);
  
  // Neutral Colors
  static const Color textDark = Color(0xFF263238);
  static const Color textMedium = Color(0xFF455A64);
  static const Color textLight = Color(0xFF90A4AE);
  static const Color border = Color(0xFFECEFF1);

  // Layout Constants
  static const double cardRadius = 20.0;
  static const double innerRadius = 12.0;

  // Elevation & Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: primaryBlue.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, accentBlue],
  );

  static LinearGradient get successGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, Color(0xFF66BB6A)],
  );

  // Text Styles
  static TextStyle get titleLarge => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle get subtitleSmall => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.white70,
    letterSpacing: 1.2,
  );

  static TextStyle get cardTitle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: textDark,
  );

  static TextStyle get cardSubtitle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textMedium,
  );
}
