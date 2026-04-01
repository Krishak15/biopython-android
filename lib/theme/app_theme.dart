import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Luminous Vitals Palette
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF0E0E0E);
  
  // Containers
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF1A1A19);
  static const Color surfaceContainerHigh = Color(0xFF202020);
  static const Color surfaceContainerHighest = Color(0xFF262626);
  static const Color surfaceBright = Color(0xFF2C2C2C);
  
  // The Pulse Accents (overridden values from user feedback: F48FB1, CE93D8, FFAB91)
  static const Color primary = Color(0xFFF48FB1); // Custom override
  static const Color primaryContainer = Color(0xFFFE97B9);
  
  static const Color secondary = Color(0xFFCE93D8); // Custom override
  static const Color secondaryContainer = Color(0xFF3F0E4C);
  
  static const Color tertiary = Color(0xFFFFAB91); // Custom override
  static const Color tertiaryContainer = Color(0xFFF7A48B);

  // Functional
  static const Color error = Color(0xFFFF716C);
  
  // Text
  static const Color onSurface = Color(0xFFE7E5E4);
  static const Color onSurfaceVariant = Color(0xFFACABAA);
  static const Color onPrimary = Color(0xFF51092A); // Roughly adapted for readability
  
  // Borders
  static const Color outlineVariant = Color(0xFF484848); // Ghost border at 15% opacity

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
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        secondaryContainer: secondaryContainer,
        surfaceContainerHighest: surfaceContainerHighest,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        displayLarge: manrope.displayLarge?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
        displayMedium: manrope.displayMedium?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
        displaySmall: manrope.displaySmall?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
        headlineLarge: manrope.headlineLarge?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
        headlineMedium: manrope.headlineMedium?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
        headlineSmall: manrope.headlineSmall?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
        titleLarge: inter.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
        titleMedium: inter.titleMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
        titleSmall: inter.titleSmall?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
        bodyLarge: inter.bodyLarge?.copyWith(color: onSurface),
        bodyMedium: inter.bodyMedium?.copyWith(color: onSurface),
        bodySmall: inter.bodySmall?.copyWith(color: onSurfaceVariant),
        labelLarge: inter.labelLarge?.copyWith(color: onSurfaceVariant),
        labelMedium: inter.labelMedium?.copyWith(color: onSurfaceVariant),
        labelSmall: inter.labelSmall?.copyWith(color: onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // 'xl' token
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black, // surface-container-lowest
        hintStyle: const TextStyle(color: onSurfaceVariant),
        labelStyle: const TextStyle(color: onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.15), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.15), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.40), width: 1), // Increased opacity on focus
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // 'full' token
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope', // Override
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        labelStyle: const TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 'sm' token
        ),
        side: BorderSide.none,
      ),
    );
  }
}
