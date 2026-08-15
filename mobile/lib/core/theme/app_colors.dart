import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/services/app_settings_service.dart';

class AppColors {
  AppColors._();

  static Color get primary => AppSettingsService.instance.primaryColor;
  static Color get secondary => AppSettingsService.instance.secondaryColor;
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color warningSoft = Color(0x28F59E0B);
  static const Color successSoft = Color(0x2822C55E);
  static const Color dangerSoft = Color(0x28EF4444);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color shadow = Color(0x1A0F172A);

  // Warna dari figma
  static const Color cardBackground = Color(0xFFFEFEFE);
  static const Color cardBorder = Color(0xAD95C1CC);
  static Color get navActive => AppSettingsService.instance.navActiveColor;
  static const Color greeting = Color(0xFF8A8A8A);
  static const Color labelMuted = Color(0x8C000000);
  static const Color textMuted = Color(0x80000000);
  static const Color textBlack = Colors.black;
}
