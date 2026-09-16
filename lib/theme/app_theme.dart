import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
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
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      cardColor: surfaceContainerLow,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: surfaceContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        error: error,
        errorContainer: errorContainer,
        surface: surface,
        surfaceContainerHighest: surfaceContainerHigh,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outlineVariant: outlineVariant,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.orbitron(color: onSurface, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.orbitron(color: onSurface, fontWeight: FontWeight.w900),
        displaySmall: GoogleFonts.orbitron(color: onSurface, fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.orbitron(color: onSurface, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.orbitron(color: onSurface, fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.rajdhani(color: onSurface, fontWeight: FontWeight.w700, letterSpacing: 1.0),
        titleLarge: GoogleFonts.orbitron(color: onSurface, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.rajdhani(color: onSurface, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        titleSmall: GoogleFonts.rajdhani(color: onSurface, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        bodyLarge: GoogleFonts.outfit(color: onSurface),
        bodyMedium: GoogleFonts.outfit(color: onSurface),
        bodySmall: GoogleFonts.outfit(color: onSurfaceVariant),
        labelLarge: GoogleFonts.rajdhani(color: onSurface, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        labelMedium: GoogleFonts.rajdhani(color: onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 1.0),
        labelSmall: GoogleFonts.rajdhani(color: onSurfaceVariant, fontWeight: FontWeight.w500, letterSpacing: 1.0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerLow,
        indicatorColor: primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: primary);
          }
          return GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: onSurfaceVariant);
        }),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      cardColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: Color(0xFFDCE7FF),
        secondary: Color(0xFFE2E8F0),
        tertiary: Color(0xFF059669),
        tertiaryContainer: Color(0xFFD1FAE5),
        error: Color(0xFFDC2626),
        errorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFFFFFFFF),
        surfaceContainerHighest: Color(0xFFCBD5E1),
        onSurface: Color(0xFF0F172A),
        onSurfaceVariant: Color(0xFF475569),
        outlineVariant: Color(0xFFE2E8F0),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.orbitron(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.orbitron(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900),
        displaySmall: GoogleFonts.orbitron(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.orbitron(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.orbitron(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.rajdhani(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700, letterSpacing: 1.0),
        titleLarge: GoogleFonts.orbitron(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.rajdhani(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700, letterSpacing: 0.5),
        titleSmall: GoogleFonts.rajdhani(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600, letterSpacing: 0.5),
        bodyLarge: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
        bodyMedium: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
        bodySmall: GoogleFonts.outfit(color: const Color(0xFF475569)),
        labelLarge: GoogleFonts.rajdhani(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700, letterSpacing: 1.5),
        labelMedium: GoogleFonts.rajdhani(color: const Color(0xFF475569), fontWeight: FontWeight.w600, letterSpacing: 1.0),
        labelSmall: GoogleFonts.rajdhani(color: const Color(0xFF475569), fontWeight: FontWeight.w500, letterSpacing: 1.0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        indicatorColor: const Color(0xFFDCE7FF),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: primary);
          }
          return GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: const Color(0xFF475569));
        }),
      ),
    );
  }
}
