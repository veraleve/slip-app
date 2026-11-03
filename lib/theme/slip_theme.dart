import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlipTheme {
  // Google Tasks Clean Material 3 Palette
  static const Color canvas = Color(0xFFF8FAFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF80868B);
  static const Color hairline = Color(0xFFE0E2EC);
  static const Color googleBlue = Color(0xFF0B57D0);
  static const Color googleBlueContainer = Color(0xFFD3E3FD);
  static const Color trapRed = Color(0xFFB3261E);
  static const Color clearedGreen = Color(0xFF137333);

  // Carbon alias for high-contrast elements
  static const Color carbon = Color(0xFF1F1F1F);
  static const Color steel = Color(0xFF5F6368);
  static const Color steelLight = Color(0xFF80868B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      primaryColor: textPrimary,
      colorScheme: const ColorScheme.light(
        surface: surface,
        primary: textPrimary,
        onPrimary: canvas,
        secondary: textSecondary,
        error: trapRed,
      ),
      dividerTheme: const DividerThemeData(
        color: hairline,
        thickness: 0.5,
        space: 24,
      ),
      // Exact Google Tasks Typography (Roboto & Roboto Mono)
      textTheme: TextTheme(
        // Wordmark / Hero Titles
        displayLarge: GoogleFonts.roboto(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        // Trap Statements & Headlines
        headlineSmall: GoogleFonts.roboto(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.35,
        ),
        // Body Text / Descriptions
        bodyLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.45,
        ),
        // Monospaced Metadata & Coordinates
        labelLarge: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.6,
        ),
        labelSmall: GoogleFonts.robotoMono(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
