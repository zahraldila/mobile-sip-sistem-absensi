import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
    required this.onCancel,
    this.confirmLabel = 'Ya',
    this.cancelLabel = 'Tidak',
  });

  final String title;
  final String description;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      title: Text(title, style: AppTypography.textTheme.headlineSmall),
      content: Text(description, style: AppTypography.textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelLabel, style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: AppRadius.medium)),
          child: Text(confirmLabel, style: AppTypography.textTheme.labelLarge),
        ),
      ],
    );
  }
}
