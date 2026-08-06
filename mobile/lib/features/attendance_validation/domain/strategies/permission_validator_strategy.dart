import 'package:permission_handler/permission_handler.dart';
import '../../services/permission_service.dart';
import '../entities/validation_failure.dart';
import '../entities/validation_step_status.dart';
import 'attendance_validator_strategy.dart';

class PermissionValidatorStrategy implements AttendanceValidatorStrategy {
  final PermissionService permissionService;

  PermissionValidatorStrategy({required this.permissionService});

  @override
  String get stepKey => 'permission';

  @override
  String get displayName => 'Izin Lokasi & Sensor';

  @override
  Future<ValidationStepResult> validate(ValidationContext context) async {
    if (!context.config.requirePermission) {
      context.stepDetails[stepKey] = ValidationStepStatus.skipped;
      return const ValidationStepResult.skipped();
    }

    context.stepDetails[stepKey] = ValidationStepStatus.running;

    try {
      bool isGranted = await permissionService.isLocationPermissionGranted();

      if (!isGranted) {
        // Request permission if not granted
        final requestStatus = await permissionService.requestLocationPermission();
        isGranted = requestStatus.isGranted;

        if (requestStatus.isPermanentlyDenied) {
          context.stepDetails[stepKey] = ValidationStepStatus.failed;
          final failure = const PermissionDeniedFailure(
            message: 'Izin akses lokasi ditolak secara permanen.',
            isPermanentlyDenied: true,
            actionHint: 'Buka Pengaturan Aplikasi dan izinkan akses lokasi.',
          );
          context.failure = failure;
          return ValidationStepResult.failed(failure);
        }
      }

      if (!isGranted) {
        context.stepDetails[stepKey] = ValidationStepStatus.failed;
        final failure = const PermissionDeniedFailure(
          message: 'Izin akses lokasi diperlukan untuk melakukan absensi.',
          isPermanentlyDenied: false,
          actionHint: 'Izinkan akses lokasi saat diminta oleh aplikasi.',
        );
        context.failure = failure;
        return ValidationStepResult.failed(failure);
      }

      context.isPermissionGranted = true;
      context.stepDetails[stepKey] = ValidationStepStatus.passed;
      return const ValidationStepResult.passed();
    } catch (e) {
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      final failure = UnknownValidationFailure(
        error: e.toString(),
        message: 'Gagal memeriksa izin akses lokasi.',
      );
      context.failure = failure;
      return ValidationStepResult.failed(failure);
    }
  }
}
