import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.subtitle,
  });

  final String name;
  final String? imageUrl;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.large,
            image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover) : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '',
                    style: AppTypography.textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
