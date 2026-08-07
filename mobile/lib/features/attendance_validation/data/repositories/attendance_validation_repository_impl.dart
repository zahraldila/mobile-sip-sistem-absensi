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
  Future<List<OfficeRule>> getOfficeRules() async {
    return await remoteDataSource.getOfficeRules();
  }

  @override
  Future<OfficeRule> getOfficeRule() async {
    return await remoteDataSource.getOfficeRule();
  }

  @override
  Future<ValidationResult> validasiWFO({List<OfficeRule>? officeRules}) async {
    return await validateAttendance(
      config: ValidationConfig.wfo(officeRules: officeRules),
    );
  }

  @override
  Future<ValidationResult> validateAttendance({
    required ValidationConfig config,
  }) async {
    // 1. Resolve All Office Rules
    final officeRules = config.customOfficeRules ??
        (config.customOfficeRule != null
            ? [config.customOfficeRule!]
            : await getOfficeRules());

    // 2. Initialize Context with All Offices
    final context = ValidationContext(
      config: config,
      officeRules: officeRules,
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
    ValidationFailure? finalFailure;

    // 4. Execute Pipeline Sequentially
    for (int i = 0; i < pipeline.length; i++) {
      final strategy = pipeline[i];
      final stepResult = await strategy.validate(context);

      if (!stepResult.isPassed) {
        finalFailure ??= stepResult.failure;

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

    // 5. Evaluate Overall Success based on Attendance Mode Rules
    bool isOverallSuccess = true;

    if (config.requirePermission && !context.isPermissionGranted) {
      isOverallSuccess = false;
    } else if (config.requireGps &&
        (!context.isGpsEnabled || context.latitude == null)) {
      isOverallSuccess = false;
    } else if (config.requireDistance && config.requireWifi) {
      // WFO Rule: Pegawai boleh absen di kantor manapun.
      // Valid jika cocok dengan salah satu kantor (WiFi cocok ATAU dalam radius lokasi_kantor).
      final isOfficeMatched = context.isDistanceValid || context.isWifiValid;
      if (!isOfficeMatched) {
        isOverallSuccess = false;
      } else {
        isOverallSuccess = true;
        finalFailure = null; // Clear non-fatal failure because OR condition is satisfied
      }
    } else if (config.requireDistance && !context.isDistanceValid) {
      isOverallSuccess = false;
    } else if (config.requireWifi && !context.isWifiValid) {
      isOverallSuccess = false;
    }

    // 6. Construct Final Result
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
            context.failure ??
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

    // 7. Asynchronously submit telemetry log in background (non-blocking)
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
