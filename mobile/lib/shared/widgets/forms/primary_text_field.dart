import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class PrimaryTextField extends StatelessWidget {
  const PrimaryTextField({
    this.controller,
    this.label,
    this.hintText,
    this.obscureText = false,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      style: AppTypography.textTheme.bodyMedium,
    );
  }
}
