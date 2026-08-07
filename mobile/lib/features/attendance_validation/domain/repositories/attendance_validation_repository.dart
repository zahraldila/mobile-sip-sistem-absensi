import '../entities/office_rule.dart';
import '../entities/validation_config.dart';
import '../entities/validation_result.dart';

abstract class AttendanceValidationRepository {
  /// Fetches all office validation rules (coordinates, allowed SSIDs, radius)
  Future<List<OfficeRule>> getOfficeRules();

  /// Fetches a single office rule (first office or default fallback)
  Future<OfficeRule> getOfficeRule();

  /// Runs the full validation pipeline according to config
  Future<ValidationResult> validateAttendance({
    required ValidationConfig config,
  });

  /// Convenience method for WFO validation across all offices
  Future<ValidationResult> validasiWFO({List<OfficeRule>? officeRules});

  /// Submits the telemetry/validation log to backend (API preparation)
  Future<bool> submitValidationLog(ValidationResult result);
}
