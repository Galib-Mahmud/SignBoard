import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Professional High-Contrast Palette
  static const Color primaryDark = Color(0xFF0F172A); // Slate-900 High Contrast Text
  static const Color secondaryDark = Color(0xFF1E293B); // Slate-800
  static const Color textSecondary = Color(0xFF475569); // Slate-600 (High contrast, easy to read)
  static const Color textMuted = Color(0xFF64748B); // Slate-500
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgCanvas = Color(0xFFF8FAFC); // Slate-50 Crisp Canvas
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200 Card border
  static const Color whatsAppGreen = Color(0xFF25D366); // #25D366 WhatsApp action
  static const Color goRouteBg = Color(0xFFF1F5F9); // Slate-100 Go route action
  static const Color accentBlue = Color(0xFF2563EB); // Royal Blue
  static const Color dangerRed = Color(0xFFDC2626); // Red-600

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgCanvas,
      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        secondary: accentBlue,
        surface: bgSurface,
        error: dangerRed,
        onPrimary: Colors.white,
        onSurface: primaryDark,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: primaryDark,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryDark,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: primaryDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryDark),
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: primaryDark,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCanvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderLight),
        ),
      ),
    );
  }
}
