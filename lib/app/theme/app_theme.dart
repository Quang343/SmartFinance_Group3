import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00D09E), // FinSmart Green
        primary: const Color(0xFF00D09E), // Force exact primary color
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF06150F), // Spendly Deep forest green background
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00D09E), // FinSmart Green
        primary: const Color(0xFF00D09E), // Force exact primary color
        brightness: Brightness.dark,
        surface: const Color(0xFF0C2C1F),
        background: const Color(0xFF06150F),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF06150F),
      ),
    );
  }
}
