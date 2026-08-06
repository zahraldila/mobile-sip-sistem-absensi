import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // Definisi warna dasar agar konsisten (bisa juga ambil dari AppColors nanti)
  static const Color _textPrimary = Color(0xFF0F172A);   // Hitam kebiruan gelap
  static const Color _textSecondary = Color(0xFF64748B); // Abu-abu sedang
  static const Color _textMuted = Color(0xFF94A3B8);     // Abu-abu terang
  static const Color _white = Color(0xFFFFFFFF);

  static TextTheme textTheme = TextTheme(
    // --- DISPLAY ---
    displayLarge: GoogleFonts.poppins(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: _textPrimary,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: _textPrimary,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1,
      color: _textPrimary,
    ),

    // --- HEADLINE ---
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: _textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),

    // --- TITLE ---
    titleLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _textSecondary,
      letterSpacing: 0.2,
    ),

    // --- BODY  ---
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: _textPrimary,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _textSecondary,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: _textMuted,
      height: 1.4,
    ),

    // --- LABEL  ---
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: _white,
      letterSpacing: 0.2,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _textSecondary,
      letterSpacing: 0.3,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: _textMuted,
      letterSpacing: 0.4,
    ),
  );
}