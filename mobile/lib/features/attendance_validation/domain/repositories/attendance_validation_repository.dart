import '../entities/office_rule.dart';
import '../entities/validation_config.dart';
import '../entities/validation_result.dart';

abstract class AttendanceValidationRepository {
  /// Fetches the office validation rules (coordinates, allowed SSIDs, radius)
  Future<OfficeRule> getOfficeRule();

  /// Runs the full validation pipeline according to config
  Future<ValidationResult> validateAttendance({
    required ValidationConfig config,
  });

  /// Submits the telemetry/validation log to backend (API preparation)
  Future<bool> submitValidationLog(ValidationResult result);
}
