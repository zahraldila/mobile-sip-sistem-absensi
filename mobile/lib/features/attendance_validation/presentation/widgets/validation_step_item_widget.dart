import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/validation_step_status.dart';

class ValidationStepItemWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final ValidationStepStatus status;

  const ValidationStepItemWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: AppRadius.medium,
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _getIconColor(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: _getSubtitleColor(),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildTrailingIndicator(),
        ],
      ),
    );
  }

  Widget _buildTrailingIndicator() {
    switch (status) {
      case ValidationStepStatus.idle:
        return const SizedBox(
          width: 22,
          height: 22,
          child: Icon(Icons.circle_outlined, size: 18, color: AppColors.textDisabled),
        );
      case ValidationStepStatus.running:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      case ValidationStepStatus.passed:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case ValidationStepStatus.failed:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        );
      case ValidationStepStatus.skipped:
        return const SizedBox(
          width: 22,
          height: 22,
          child: Icon(Icons.remove_circle_outline, size: 18, color: AppColors.textDisabled),
        );
    }
  }

  Color _getBackgroundColor() {
    switch (status) {
      case ValidationStepStatus.passed:
        return const Color(0xFFF0FDF4);
      case ValidationStepStatus.failed:
        return const Color(0xFFFEF2F2);
      case ValidationStepStatus.running:
        return const Color(0xFFEFF6FF);
      default:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case ValidationStepStatus.passed:
        return AppColors.success.withValues(alpha: 0.3);
      case ValidationStepStatus.failed:
        return AppColors.danger.withValues(alpha: 0.3);
      case ValidationStepStatus.running:
        return AppColors.primary.withValues(alpha: 0.3);
      default:
        return AppColors.border;
    }
  }

  Color _getIconBackgroundColor() {
    switch (status) {
      case ValidationStepStatus.passed:
        return AppColors.success.withValues(alpha: 0.12);
      case ValidationStepStatus.failed:
        return AppColors.danger.withValues(alpha: 0.12);
      case ValidationStepStatus.running:
        return AppColors.primary.withValues(alpha: 0.12);
      default:
        return AppColors.surfaceAlt;
    }
  }

  Color _getIconColor() {
    switch (status) {
      case ValidationStepStatus.passed:
        return AppColors.success;
      case ValidationStepStatus.failed:
        return AppColors.danger;
      case ValidationStepStatus.running:
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getSubtitleColor() {
    switch (status) {
      case ValidationStepStatus.passed:
        return AppColors.success;
      case ValidationStepStatus.failed:
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}
