import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Editorial Luminescence Palette
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF0E0E0E);
  
  // Containers
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF1A1A19);
  static const Color surfaceContainerHigh = Color(0xFF202020);
  static const Color surfaceContainerHighest = Color(0xFF262626);
  static const Color surfaceBright = Color(0xFF2C2C2C);
  
  // The Pulse Accents
  static const Color primary = Color(0xFFFFACC6); // Neon Pink
  static const Color primaryContainer = Color(0xFFFE97B9);
  
  static const Color secondary = Color(0xFFEFB1F9); // Lavender
  static const Color secondaryContainer = Color(0xFF3F0E4C);
  
  static const Color tertiary = Color(0xFFFFB59E); // Pastel Orange
  static const Color tertiaryContainer = Color(0xFFF7A48B);

  // Functional
  static const Color error = Color(0xFFFF716C);
  
  // Text
  static const Color onSurface = Color(0xFFE7E5E4);
  static const Color onSurfaceVariant = Color(0xFFACABAA);
  static const Color onPrimary = Color(0xFF6E2241); // Adapted from Stitch
  static const Color onSecondary = Color(0xFF5D2C69);
  static const Color onTertiary = Color(0xFF68301D);
  
  // Borders
  static const Color outlineVariant = Color(0xFF484848); // For Ghost Borders

  static ThemeData get darkTheme {
    final manrope = GoogleFonts.manropeTextTheme();
    final inter = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        error: error,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onTertiary: onTertiary,
        primaryContainer: primaryContainer,
        secondaryContainer: secondaryContainer,
        tertiaryContainer: tertiaryContainer,
        surfaceContainerHighest: surfaceContainerHighest,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        displayLarge: manrope.displayLarge?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        displayMedium: manrope.displayMedium?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displaySmall: manrope.displaySmall?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: manrope.headlineLarge?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: manrope.headlineMedium?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: manrope.headlineSmall?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.bold,
        ),
        titleLarge: inter.titleLarge?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.w600,
        ),
        titleMedium: inter.titleMedium?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.w600,
        ),
        titleSmall: inter.titleSmall?.copyWith(
          color: onSurface, 
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: inter.bodyLarge?.copyWith(color: onSurface),
        bodyMedium: inter.bodyMedium?.copyWith(color: onSurface),
        bodySmall: inter.bodySmall?.copyWith(
          color: onSurfaceVariant,
          fontSize: 12,
        ),
        labelLarge: inter.labelLarge?.copyWith(
          color: onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
        labelMedium: inter.labelMedium?.copyWith(
          color: onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
        labelSmall: inter.labelSmall?.copyWith(
          color: onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // 'xl' token
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black, // surface-container-lowest
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: onSurfaceVariant, fontSize: 13),
        labelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // 'full' token
          ),
          textStyle: manrope.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: manrope.headlineSmall?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        labelStyle: const TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),
    );
  }
}
