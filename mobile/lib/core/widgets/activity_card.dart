import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_shadow.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.icon,
    this.statusColor = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final String status;
  final Widget? icon;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.medium,
              ),
              child: icon,
            ),
          if (icon != null) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTypography.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                (statusColor.r * 255).round(),
                (statusColor.g * 255).round(),
                (statusColor.b * 255).round(),
                0.12,
              ),
              borderRadius: AppRadius.pill,
            ),
            child: Text(status, style: AppTypography.textTheme.labelSmall?.copyWith(color: statusColor)),
          ),
        ],
      ),
    );
  }
}
