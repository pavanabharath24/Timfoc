import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LofiTheme {
  // Brand colors from HTML
  static const Color background = Color(0xFF111125);
  static const Color surfaceLow = Color(0xFF1a1a2e);
  static const Color surfaceHigh = Color(0xFF28283d);
  static const Color surfaceHighest = Color(0xFF333348);
  static const Color primary = Color(0xFFd4bbff);
  static const Color primaryContainer = Color(0xFF412175);
  static const Color secondary = Color(0xFFffb954);
  static const Color secondaryContainer = Color(0xFFc3841b);
  static const Color outline = Color(0xFF474553);
  static const Color onSurface = Color(0xFFe2e0fc);
  static const Color onSurfaceVariant = Color(0xFFc9c4d5);
  static const Color error = Color(0xFFffb4ab);

  static ThemeData get lightTheme {
    // Actually this is just the Dark Theme forced on for the premium aesthetic.
    return darkTheme;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: background,
        surfaceContainerHighest: surfaceHighest,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        titleSmall: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.manrope(color: onSurface),
        bodyMedium: GoogleFonts.manrope(color: onSurfaceVariant),
        bodySmall: GoogleFonts.manrope(color: onSurfaceVariant),
        labelLarge: GoogleFonts.manrope(color: primary, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        labelMedium: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        labelSmall: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: outline),
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: secondary),
      ),
      iconTheme: const IconThemeData(
        color: onSurface,
        size: 24,
      ),
    );
  }
}
