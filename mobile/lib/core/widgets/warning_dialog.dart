import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class WarningDialog extends StatelessWidget {
  const WarningDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onAcknowledge,
    this.buttonLabel = 'Mengerti',
  });

  final String title;
  final String description;
  final VoidCallback onAcknowledge;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      title: Text(title, style: AppTypography.textTheme.headlineSmall?.copyWith(color: AppColors.warning)),
      content: Text(description, style: AppTypography.textTheme.bodyMedium),
      actions: [
        FilledButton(
          onPressed: onAcknowledge,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: AppRadius.medium)),
          child: Text(buttonLabel, style: AppTypography.textTheme.labelLarge),
        ),
      ],
    );
  }
}
