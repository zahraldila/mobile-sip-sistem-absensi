import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large,
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTypography.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.textTheme.bodyMedium, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: AppRadius.medium), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: Text(actionLabel!, style: AppTypography.textTheme.labelLarge)),
          ],
        ],
      ),
    );
  }
}
