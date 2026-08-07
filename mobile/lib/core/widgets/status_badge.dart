import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

enum StatusBadgeType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
  });

  final String label;
  final StatusBadgeType type;

  Color get backgroundColor {
    switch (type) {
      case StatusBadgeType.success:
        return Color.fromRGBO(
          (AppColors.success.r * 255).round(),
          (AppColors.success.g * 255).round(),
          (AppColors.success.b * 255).round(),
          0.16,
        );
      case StatusBadgeType.warning:
        return Color.fromRGBO(
          (AppColors.warning.r * 255).round(),
          (AppColors.warning.g * 255).round(),
          (AppColors.warning.b * 255).round(),
          0.16,
        );
      case StatusBadgeType.danger:
        return Color.fromRGBO(
          (AppColors.danger.r * 255).round(),
          (AppColors.danger.g * 255).round(),
          (AppColors.danger.b * 255).round(),
          0.16,
        );
      case StatusBadgeType.neutral:
        return AppColors.border;
      case StatusBadgeType.info:
        return Color.fromRGBO(
          (AppColors.primary.r * 255).round(),
          (AppColors.primary.g * 255).round(),
          (AppColors.primary.b * 255).round(),
          0.12,
        );
    }
  }

  Color get textColor {
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.success;
      case StatusBadgeType.warning:
        return AppColors.warning;
      case StatusBadgeType.danger:
        return AppColors.danger;
      case StatusBadgeType.neutral:
        return AppColors.textSecondary;
      case StatusBadgeType.info:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(color: textColor),
      ),
    );
  }
}
