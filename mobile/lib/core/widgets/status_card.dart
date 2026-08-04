import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_shadow.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color = AppColors.primary,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Widget? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  (color.r * 255).round(),
                  (color.g * 255).round(),
                  (color.b * 255).round(),
                  0.12,
                ),
                borderRadius: AppRadius.medium,
              ),
              child: icon,
            ),
          if (icon != null) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(value, style: AppTypography.textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: AppTypography.textTheme.bodySmall),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
