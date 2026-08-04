import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: const Color(0xFF0F172A),
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    ),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    headlineSmall: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF475569),
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0F172A),
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF475569),
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF64748B),
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFFFFFF),
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF475569),
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
    ),
  );
}
