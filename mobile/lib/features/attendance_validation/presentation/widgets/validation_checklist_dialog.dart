import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/validation_config.dart';
import '../../domain/entities/validation_result.dart';
import '../../domain/entities/validation_step_status.dart';
import '../cubit/attendance_validation_cubit.dart';
import '../cubit/attendance_validation_state.dart';
import 'validation_step_item_widget.dart';

class ValidationChecklistDialog extends StatefulWidget {
  final ValidationConfig config;

  const ValidationChecklistDialog({
    super.key,
    this.config = const ValidationConfig(),
  });

  /// Helper static method to open the dialog easily from any feature
  static Future<ValidationResult?> show(
    BuildContext context, {
    ValidationConfig config = const ValidationConfig(),
  }) {
    return showDialog<ValidationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValidationChecklistDialog(config: config),
    );
  }

  @override
  State<ValidationChecklistDialog> createState() =>
      _ValidationChecklistDialogState();
}

class _ValidationChecklistDialogState extends State<ValidationChecklistDialog> {
  late AttendanceValidationCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceValidationCubit>();
    _startValidation();
  }

  void _startValidation() {
    _cubit.runValidation(config: widget.config);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        elevation: 12,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocConsumer<AttendanceValidationCubit, AttendanceValidationState>(
            listener: (context, state) {
              if (state is AttendanceValidationSuccess) {
                // Auto close after brief moment on success
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (context.mounted) {
                    Navigator.of(context).pop(state.result);
                  }
                });
              }
            },
            builder: (context, state) {
              final stepDetails = _extractStepDetails(state);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(state),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.md),

                  // Steps List
                  ValidationStepItemWidget(
                    title: '1. Izin Akses Lokasi',
                    subtitle: _getPermissionSubtitle(stepDetails['permission']),
                    icon: Icons.security_rounded,
                    status: stepDetails['permission'] ?? ValidationStepStatus.idle,
                  ),
                  ValidationStepItemWidget(
                    title: '2. GPS & Layanan Lokasi',
                    subtitle: _getGpsSubtitle(stepDetails['gps'], state),
                    icon: Icons.location_on_outlined,
                    status: stepDetails['gps'] ?? ValidationStepStatus.idle,
                  ),
                  if (widget.config.requireDistance)
                    ValidationStepItemWidget(
                      title: '3. Radius Lokasi Kantor',
                      subtitle: _getDistanceSubtitle(stepDetails['distance'], state),
                      icon: Icons.social_distance_rounded,
                      status: stepDetails['distance'] ?? ValidationStepStatus.idle,
                    ),
                  if (widget.config.requireWifi)
                    ValidationStepItemWidget(
                      title: '4. Wi-Fi Resmi Perusahaan',
                      subtitle: _getWifiSubtitle(stepDetails['wifi'], state),
                      icon: Icons.wifi_rounded,
                      status: stepDetails['wifi'] ?? ValidationStepStatus.idle,
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // Failure Banner if any
                  if (state is AttendanceValidationFailureState) ...[
                    _buildFailureBanner(state),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Action Buttons
                  _buildActionButtons(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AttendanceValidationState state) {
    String title = 'Validasi Absensi';
    String subtitle = 'Memverifikasi parameter keamanan absensi...';
    Color iconColor = AppColors.primary;
    IconData icon = Icons.verified_user_outlined;

    if (state is AttendanceValidationSuccess) {
      title = 'Validasi Berhasil';
      subtitle = 'Seluruh parameter absensi memenuhi syarat.';
      iconColor = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (state is AttendanceValidationFailureState) {
      title = 'Validasi Tidak Lolos';
      subtitle = 'Beberapa parameter belum terpenuhi.';
      iconColor = AppColors.danger;
      icon = Icons.error_outline_rounded;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFailureBanner(AttendanceValidationFailureState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.failure.message,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
                if (state.failure.actionHint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    state.failure.actionHint!,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AttendanceValidationState state) {
    if (state is AttendanceValidationFailureState) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(state.result),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Text(
                'Tutup',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (state.directActionLabel != null && state.directActionType != null)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _cubit.executeAction(
                  state.directActionType!,
                  widget.config,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  elevation: 0,
                ),
                child: Text(
                  state.directActionLabel!,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    if (state is AttendanceValidationSuccess) {
      return ElevatedButton(
        onPressed: () => Navigator.of(context).pop(state.result),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          elevation: 0,
        ),
        child: Text(
          'Lanjutkan Absensi',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Center(
      child: Text(
        'Sedang memeriksa validasi...',
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Map<String, ValidationStepStatus> _extractStepDetails(
      AttendanceValidationState state) {
    if (state is AttendanceValidationInProgress) {
      return state.stepStatuses;
    } else if (state is AttendanceValidationSuccess) {
      return state.result.stepDetails;
    } else if (state is AttendanceValidationFailureState) {
      return state.result.stepDetails;
    }
    return {};
  }

  String? _getPermissionSubtitle(ValidationStepStatus? status) {
    if (status == ValidationStepStatus.passed) return 'Izin lokasi aktif';
    if (status == ValidationStepStatus.failed) return 'Izin lokasi ditolak';
    return null;
  }

  String? _getGpsSubtitle(
      ValidationStepStatus? status, AttendanceValidationState state) {
    if (status == ValidationStepStatus.passed) {
      if (state is AttendanceValidationSuccess) {
        return 'Lat: ${state.result.latitude?.toStringAsFixed(4)}, Acc: ${state.result.accuracy?.toStringAsFixed(1)}m';
      }
      return 'Koordinat lokasi berhasil diperoleh';
    }
    if (status == ValidationStepStatus.failed) return 'Layanan GPS mati / timeout';
    return null;
  }

  String? _getDistanceSubtitle(
      ValidationStepStatus? status, AttendanceValidationState state) {
    if (status == ValidationStepStatus.passed) {
      if (state is AttendanceValidationSuccess && state.result.distance != null) {
        return 'Jarak: ${state.result.distance?.toStringAsFixed(1)}m (Dalam radius kantor)';
      }
      return 'Dalam radius kantor';
    }
    if (status == ValidationStepStatus.failed) {
      if (state is AttendanceValidationFailureState &&
          state.result.distance != null) {
        return 'Jarak: ${state.result.distance?.toStringAsFixed(1)}m (Di luar radius kantor)';
      }
      return 'Di luar radius kantor';
    }
    return null;
  }

  String? _getWifiSubtitle(
      ValidationStepStatus? status, AttendanceValidationState state) {
    if (status == ValidationStepStatus.passed) {
      if (state is AttendanceValidationSuccess && state.result.ssid != null) {
        return 'Terhubung: ${state.result.ssid}';
      }
      return 'Terhubung ke Wi-Fi kantor';
    }
    if (status == ValidationStepStatus.failed) {
      return 'Tidak terhubung ke Wi-Fi kantor';
    }
    return null;
  }
}
