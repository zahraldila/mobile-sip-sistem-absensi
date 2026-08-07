import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/office_rule.dart';
import '../../domain/entities/validation_config.dart';
import '../../domain/entities/validation_failure.dart';
import '../../domain/entities/validation_result.dart';
import '../../domain/entities/validation_step_status.dart';
import '../../domain/usecases/validate_attendance_usecase.dart';
import '../../services/gps_service.dart';
import '../../services/permission_service.dart';
import 'attendance_validation_state.dart';

class AttendanceValidationCubit extends Cubit<AttendanceValidationState> {
  final ValidateAttendanceUseCase validateAttendanceUseCase;
  final PermissionService permissionService;
  final GpsService gpsService;

  AttendanceValidationCubit({
    required this.validateAttendanceUseCase,
    required this.permissionService,
    required this.gpsService,
  }) : super(const AttendanceValidationInitial());

  /// Convenience method to run WFO validation across all offices
  Future<ValidationResult> validasiWFO({List<OfficeRule>? officeRules}) async {
    return await runValidation(
      config: ValidationConfig.wfo(officeRules: officeRules),
    );
  }

  /// Runs the full validation workflow
  Future<ValidationResult> runValidation({
    ValidationConfig config = const ValidationConfig(),
  }) async {
    emit(AttendanceValidationInProgress(
      activeStepKey: 'permission',
      activeStepName: 'Memeriksa Izin Lokasi...',
      stepStatuses: {
        'permission': ValidationStepStatus.running,
        'gps': ValidationStepStatus.idle,
        'distance': ValidationStepStatus.idle,
        'wifi': ValidationStepStatus.idle,
      },
    ));

    final result = await validateAttendanceUseCase.execute(config: config);

    if (result.isValid) {
      emit(AttendanceValidationSuccess(result: result));
    } else {
      final failure = result.failure ??
          const UnknownValidationFailure(error: 'Validasi tidak lolos.');

      String? actionLabel;
      String? actionType;

      if (failure is PermissionDeniedFailure) {
        if (failure.isPermanentlyDenied) {
          actionLabel = 'Buka Pengaturan';
          actionType = 'open_settings';
        } else {
          actionLabel = 'Minta Izin Ulang';
          actionType = 'request_permission';
        }
      } else if (failure is GpsDisabledFailure) {
        actionLabel = 'Aktifkan GPS';
        actionType = 'enable_gps';
      } else if (failure is WifiNotConnectedFailure ||
          failure is WifiNotAllowedFailure) {
        actionLabel = 'Hubungkan Wi-Fi';
        actionType = 'connect_wifi';
      } else {
        actionLabel = 'Coba Lagi';
        actionType = 'retry';
      }

      emit(AttendanceValidationFailureState(
        result: result,
        failure: failure,
        directActionLabel: actionLabel,
        directActionType: actionType,
      ));
    }

    return result;
  }

  /// Triggers a direct system action to resolve the failure
  Future<void> executeAction(String actionType, [ValidationConfig? config]) async {
    switch (actionType) {
      case 'open_settings':
        await permissionService.openAppSettingsPage();
        break;
      case 'enable_gps':
        await gpsService.openLocationSettings();
        break;
      case 'request_permission':
        await permissionService.requestLocationPermission();
        if (config != null) {
          await runValidation(config: config);
        }
        break;
      case 'retry':
        if (config != null) {
          await runValidation(config: config);
        }
        break;
      default:
        break;
    }
  }

  /// Resets state to initial
  void reset() {
    emit(const AttendanceValidationInitial());
  }
}
