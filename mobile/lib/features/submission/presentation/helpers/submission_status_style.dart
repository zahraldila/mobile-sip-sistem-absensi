import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/status_badge.dart';
import '../../domain/entities/submission_status.dart';

class SubmissionStatusStyle {
  const SubmissionStatusStyle({
    required this.iconColor,
    required this.iconBackground,
    required this.badgeVariant,
  });

  final Color iconColor;
  final Color iconBackground;
  final StatusBadgeType badgeVariant;

  static SubmissionStatusStyle fromStatus(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.pending:
        return const SubmissionStatusStyle(
          iconColor: AppColors.warning,
          iconBackground: AppColors.warningSoft,
          badgeVariant: StatusBadgeType.warning,
        );
      case SubmissionStatus.disetujui:
        return const SubmissionStatusStyle(
          iconColor: AppColors.success,
          iconBackground: AppColors.successSoft,
          badgeVariant: StatusBadgeType.success,
        );
      case SubmissionStatus.ditolak:
        return const SubmissionStatusStyle(
          iconColor: AppColors.danger,
          iconBackground: AppColors.dangerSoft,
          badgeVariant: StatusBadgeType.danger,
        );
      case SubmissionStatus.unknown:
        return const SubmissionStatusStyle(
          iconColor: AppColors.textPrimary,
          iconBackground: AppColors.surfaceAlt,
          badgeVariant: StatusBadgeType.info,
        );
    }
  }
}
