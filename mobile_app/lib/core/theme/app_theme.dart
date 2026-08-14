import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Renkler
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  static const Color primaryColor = Color(0xFFFF8C00);

  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFBC02D);
  static const Color highColor = Color(0xFFFB8C00);
  static const Color errorColor = Color(0xFFE53935);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: backgroundColor,

      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        surface: surfaceColor,
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: backgroundColor,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
