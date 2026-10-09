import 'package:flutter/material.dart';

class PryceColors {
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color secondaryNavy = Color(0xFF0D47A1);
  static const Color accentAmber = Color(0xFFFFA000);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF212121);
  static const Color textMuted = Color(0xFF757575);
}

class PryceTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: PryceColors.primaryRed,
      scaffoldBackgroundColor: PryceColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PryceColors.primaryRed,
        primary: PryceColors.primaryRed,
        secondary: PryceColors.secondaryNavy,
        tertiary: PryceColors.accentAmber,
        surface: PryceColors.cardBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor:  const Color(0xFFFF4400),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  const Color(0xFFFF4400),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}