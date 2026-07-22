import 'package:flutter/material.dart';

class AfriTheme {
  // Brand Color Tokens
  static const Color rangelandGreen = Color(0xFF2E7D32);
  static const Color savannaAmber = Color(0xFFF57C00);
  static const Color paleVeldSand = Color(0xFFF9FBE7);
  static const Color earthCharcoal = Color(0xFF1A1C18);
  static const Color hazardRed = Color(0xFFD32F2F);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: rangelandGreen,
        primary: rangelandGreen,
        secondary: savannaAmber,
        background: paleVeldSand,
        surface: surfaceWhite,
        error: hazardRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: earthCharcoal,
        onSurface: earthCharcoal,
      ),
      scaffoldBackgroundColor: paleVeldSand,
      appBarTheme: const AppBarTheme(
        backgroundColor: rangelandGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: rangelandGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: rangelandGreen,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: rangelandGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: rangelandGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: hazardRed, width: 1.5),
        ),
      ),
    );
  }
}
