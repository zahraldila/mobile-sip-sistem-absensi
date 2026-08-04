import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onClose,
    this.buttonLabel = 'Tutup',
  });

  final String title;
  final String description;
  final VoidCallback onClose;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      title: Text(title, style: AppTypography.textTheme.headlineSmall?.copyWith(color: AppColors.success)),
      content: Text(description, style: AppTypography.textTheme.bodyMedium),
      actions: [
        FilledButton(
          onPressed: onClose,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: AppRadius.medium)),
          child: Text(buttonLabel, style: AppTypography.textTheme.labelLarge),
        ),
      ],
    );
  }
}
