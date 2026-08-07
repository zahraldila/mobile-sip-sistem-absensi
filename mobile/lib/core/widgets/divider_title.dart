import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class DividerTitle extends StatelessWidget {
  const DividerTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppColors.border),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.textTheme.titleMedium),
            if (subtitle != null) Text(subtitle!, style: AppTypography.textTheme.bodySmall),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: AppColors.border),
        ),
      ],
    );
  }
}
