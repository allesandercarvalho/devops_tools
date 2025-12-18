import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color background = Color(0xFF0f172a); // Slate 900
  static const Color surface = Color(0xFF1e293b);    // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700
  
  static const Color primary = Color(0xFF8b5cf6);    // Violet 500
  static const Color primaryDark = Color(0xFF7c3aed); // Violet 600
  static const Color secondary = Color(0xFF0ea5e9);  // Sky 500
  static const Color accent = Color(0xFFec4899);     // Pink 500
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94a3b8); // Slate 400
  static const Color textMuted = Color(0xFF64748b);     // Slate 500
  
  static const Color success = Color(0xFF22c55e);    // Green 500
  static const Color warning = Color(0xFFeab308);    // Yellow 500
  static const Color error = Color(0xFFef4444);      // Red 500
  static const Color info = Color(0xFF3b82f6);       // Blue 500

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF0284c7), secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        displaySmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.05)),
    );
  }
  
  // Custom Styles
  static TextStyle get codeStyle => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    color: const Color(0xFFe2e8f0),
  );
}
