import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(subtitle!, style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
