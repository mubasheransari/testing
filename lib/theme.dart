import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6750A4); // TODO: map to Figma primary
  static const Color secondary = Color(0xFF625B71);
  static const Color surface = Color(0xFFF7F2FA);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      scaffoldBackgroundColor: surface,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}
