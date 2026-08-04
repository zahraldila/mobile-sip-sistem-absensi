import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    required this.subtitle,
    this.onNotificationTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(subtitle, style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        InkWell(
          onTap: onNotificationTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
