import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class PrimaryBadge extends StatelessWidget {
  const PrimaryBadge({
    required this.label,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pill,
      ),
      child: Text(label, style: AppTypography.textTheme.labelSmall?.copyWith(color: textColor)),
    );
  }
}
