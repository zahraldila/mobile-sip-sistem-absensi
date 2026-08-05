import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: const Color(0xFF0F172A),
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF475569),
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0F172A),
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF475569),
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF64748B),
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFFFFFF),
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF475569),
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
    ),
  );
}
