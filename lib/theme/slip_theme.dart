import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlipTheme {
  // Pure Swiss Modernist Color Palette
  static const Color canvas = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color carbon = Color(0xFF09090B);
  static const Color steel = Color(0xFF71717A);
  static const Color steelLight = Color(0xFFA1A1AA);
  static const Color hairline = Color(0xFFE4E4E7);
  static const Color trapRed = Color(0xFFDC2626);
  static const Color clearedGreen = Color(0xFF059669);
  static const Color signalBlue = Color(0xFF2563EB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      primaryColor: carbon,
      colorScheme: const ColorScheme.light(
        surface: surface,
        primary: carbon,
        onPrimary: canvas,
        secondary: steel,
        error: trapRed,
      ),
      dividerTheme: const DividerThemeData(
        color: hairline,
        thickness: 0.5,
        space: 24,
      ),
      textTheme: TextTheme(
        // Wordmark / Hero Numbers
        displayLarge: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: carbon,
          letterSpacing: -1.2,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: carbon,
          letterSpacing: -0.8,
        ),
        // Trap Statements & Headlines
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: carbon,
          height: 1.35,
          letterSpacing: -0.4,
        ),
        // Body / Conceptual Explanations
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: carbon,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: steel,
          height: 1.45,
        ),
        // Monospaced Metadata & Telemetry
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: carbon,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: steel,
          letterSpacing: 0.8,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: steelLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
