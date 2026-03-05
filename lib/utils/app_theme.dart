import 'package:flutter/material.dart';

class AppTheme {
  // RC Engenharia brand colors - BLUE palette
  static const Color primaryBlue = Color(0xFF1A3A6B);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color skyBlue = Color(0xFF60A5FA);
  static const Color darkBlue = Color(0xFF0F2447);
  static const Color backgroundBlue = Color(0xFFF0F4FF);

  // Semaphore colors
  static const Color riskGreen = Color(0xFF22C55E);
  static const Color riskYellow = Color(0xFFF59E0B);
  static const Color riskRed = Color(0xFFEF4444);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color gray = Color(0xFF94A3B8);
  static const Color darkGray = Color(0xFF334155);
  static const Color cardShadow = Color(0x1A1A3A6B);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: accentBlue,
          surface: white,
        ),
        scaffoldBackgroundColor: backgroundBlue,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentBlue,
            side: const BorderSide(color: accentBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 4,
          shadowColor: cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: riskRed),
          ),
          labelStyle: const TextStyle(color: darkGray),
          hintStyle: TextStyle(color: gray),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: backgroundBlue,
          selectedColor: accentBlue,
          labelStyle: const TextStyle(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

  static Color getRiskColor(String color) {
    switch (color) {
      case 'green':
        return riskGreen;
      case 'yellow':
        return riskYellow;
      case 'red':
        return riskRed;
      default:
        return gray;
    }
  }

  static LinearGradient get headerGradient => const LinearGradient(
        colors: [darkBlue, primaryBlue, accentBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get cardGradient => const LinearGradient(
        colors: [primaryBlue, accentBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
