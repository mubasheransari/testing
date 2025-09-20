import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    final textTheme = TextTheme(
      displaySmall: GoogleFonts.getFont(Tokens.fontFamily, textStyle: Tokens.display),
      headlineSmall: GoogleFonts.getFont(Tokens.fontFamily, textStyle: Tokens.headline),
      titleMedium: GoogleFonts.getFont(Tokens.fontFamily, textStyle: Tokens.title),
      bodyLarge: GoogleFonts.getFont(Tokens.fontFamily, textStyle: Tokens.body),
      bodyMedium: GoogleFonts.getFont(Tokens.fontFamily, textStyle: Tokens.body),
      labelLarge: GoogleFonts.getFont(Tokens.fontFamily, textStyle: Tokens.label),
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Tokens.primary),
      scaffoldBackgroundColor: Tokens.surface,
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Tokens.onPrimary,
          backgroundColor: Tokens.primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.rPill)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.rPill)),
          side: BorderSide(color: Tokens.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.r12),
          borderSide: BorderSide(color: Tokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.r12),
          borderSide: BorderSide(color: Tokens.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.r12),
          borderSide: const BorderSide(color: Tokens.primary, width: 1.6),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.r16)),
      ),
    );
  }
}
