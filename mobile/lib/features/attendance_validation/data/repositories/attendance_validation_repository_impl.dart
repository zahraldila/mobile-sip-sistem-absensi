import '../../domain/entities/office_rule.dart';
import '../../domain/entities/validation_config.dart';
import '../../domain/entities/validation_failure.dart';
import '../../domain/entities/validation_result.dart';
import '../../domain/entities/validation_step_status.dart';
import '../../domain/repositories/attendance_validation_repository.dart';
import '../../domain/strategies/attendance_validator_strategy.dart';
import '../../domain/strategies/distance_validator_strategy.dart';
import '../../domain/strategies/gps_validator_strategy.dart';
import '../../domain/strategies/permission_validator_strategy.dart';
import '../../domain/strategies/wifi_validator_strategy.dart';
import '../datasources/attendance_validation_remote_datasource.dart';
import '../models/validation_payload_model.dart';

class AttendanceValidationRepositoryImpl
    implements AttendanceValidationRepository {
  final AttendanceValidationRemoteDataSource remoteDataSource;
  final PermissionValidatorStrategy permissionStrategy;
  final GpsValidatorStrategy gpsStrategy;
  final DistanceValidatorStrategy distanceStrategy;
  final WifiValidatorStrategy wifiStrategy;
  final List<AttendanceValidatorStrategy>? additionalStrategies;

  AttendanceValidationRepositoryImpl({
    required this.remoteDataSource,
    required this.permissionStrategy,
    required this.gpsStrategy,
    required this.distanceStrategy,
    required this.wifiStrategy,
    this.additionalStrategies,
  });

  @override
  Future<OfficeRule> getOfficeRule() async {
    return await remoteDataSource.getOfficeRule();
  }

  @override
  Future<ValidationResult> validateAttendance({
    required ValidationConfig config,
  }) async {
    // 1. Resolve Office Rules
    final officeRule = config.customOfficeRule ?? await getOfficeRule();

    // 2. Initialize Context
    final context = ValidationContext(
      config: config,
      officeRule: officeRule,
    );

    // 3. Assemble Strategy Pipeline
    final pipeline = <AttendanceValidatorStrategy>[
      permissionStrategy,
      gpsStrategy,
      distanceStrategy,
      wifiStrategy,
      ...?additionalStrategies,
    ];

    final now = DateTime.now();
    bool isOverallSuccess = true;
    ValidationFailure? finalFailure;

    // 4. Execute Pipeline Sequentially
    for (int i = 0; i < pipeline.length; i++) {
      final strategy = pipeline[i];
      final stepKey = strategy.stepKey;

      if (!isOverallSuccess) {
        // Mark subsequent steps as skipped
        context.stepDetails[stepKey] = ValidationStepStatus.skipped;
        continue;
      }

      final stepResult = await strategy.validate(context);

      if (!stepResult.isPassed) {
        isOverallSuccess = false;
        finalFailure = stepResult.failure;

        if (stepResult.shouldHalt) {
          // Skip remaining steps
          for (int j = i + 1; j < pipeline.length; j++) {
            context.stepDetails[pipeline[j].stepKey] =
                ValidationStepStatus.skipped;
          }
          break;
        }
      }
    }

    // 5. Construct Final Result
    final ValidationResult result;
    if (isOverallSuccess) {
      result = ValidationResult.success(
        latitude: context.latitude ?? 0.0,
        longitude: context.longitude ?? 0.0,
        accuracy: context.accuracy ?? 0.0,
        distance: context.distance,
        ssid: context.ssid,
        bssid: context.bssid,
        timestamp: now,
        stepDetails: Map.unmodifiable(context.stepDetails),
        attendanceMode: config.attendanceMode,
      );
    } else {
      result = ValidationResult.failed(
        failure: finalFailure ??
            const UnknownValidationFailure(error: 'Validasi tidak lolos.'),
        latitude: context.latitude,
        longitude: context.longitude,
        accuracy: context.accuracy,
        distance: context.distance,
        ssid: context.ssid,
        bssid: context.bssid,
        timestamp: now,
        stepDetails: Map.unmodifiable(context.stepDetails),
        attendanceMode: config.attendanceMode,
      );
    }

    // 6. Asynchronously submit telemetry log in background (non-blocking)
    unawaited(submitValidationLog(result));

    return result;
  }

  @override
  Future<bool> submitValidationLog(ValidationResult result) async {
    try {
      final payload = ValidationPayloadModel.fromEntity(result);
      return await remoteDataSource.submitValidationTelemetry(payload);
    } catch (_) {
      return false;
    }
  }
}

// Helper to avoid unawaited warnings in pure dart
void unawaited(Future<void> future) {}
