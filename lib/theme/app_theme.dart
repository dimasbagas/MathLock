import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color surfaceContainerLowest = Color(0xFF0a0e16);
  static const Color surface = Color(0xFF101622);
  static const Color background = Color(0xFF101622);
  static const Color surfaceContainerLow = Color(0xFF0f172a);
  static const Color surfaceContainer = Color(0xFF1e293b);
  static const Color surfaceContainerHigh = Color(0xFF334155);
  
  static const Color primary = Color(0xFF0d59f2); // Cobalt Blue
  static const Color primaryContainer = Color(0x1a0d59f2);
  
  static const Color tertiary = Color(0xFF10b981); // Emerald Green
  static const Color tertiaryContainer = Color(0x1a10b981);
  
  static const Color error = Color(0xFFef4444);
  static const Color errorContainer = Color(0x1aef4444);

  static const Color outlineVariant = Color(0xFF1e293b);
  
  static const Color onSurface = Color(0xFFf1f5f9);
  static const Color onSurfaceVariant = Color(0xFF94a3b8);
  static const Color onPrimary = Color(0xFFffffff);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: surfaceContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        error: error,
        surface: surface,
        surfaceContainerHighest: surfaceContainerHigh,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outlineVariant: outlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: onSurface),
        bodyMedium: GoogleFonts.inter(color: onSurface),
        bodySmall: GoogleFonts.inter(color: onSurfaceVariant),
        labelLarge: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w700),
        labelMedium: GoogleFonts.inter(color: onSurfaceVariant, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.inter(color: onSurfaceVariant, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerLow,
        indicatorColor: primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: primary);
          }
          return GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.0, color: onSurfaceVariant);
        }),
      ),
    );
  }
}
