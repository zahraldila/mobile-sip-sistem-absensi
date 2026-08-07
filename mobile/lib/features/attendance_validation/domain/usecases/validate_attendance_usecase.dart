import '../entities/office_rule.dart';
import '../entities/validation_config.dart';
import '../entities/validation_result.dart';
import '../repositories/attendance_validation_repository.dart';

class ValidateAttendanceUseCase {
  final AttendanceValidationRepository repository;

  ValidateAttendanceUseCase(this.repository);

  Future<ValidationResult> execute({
    ValidationConfig config = const ValidationConfig(),
  }) async {
    return await repository.validateAttendance(config: config);
  }

  /// Convenience method for WFO validation
  Future<ValidationResult> validasiWFO({List<OfficeRule>? officeRules}) async {
    return await repository.validasiWFO(officeRules: officeRules);
  }

  /// Alias for validasiWFO
  Future<ValidationResult> validateWfo({List<OfficeRule>? officeRules}) async {
    return await validasiWFO(officeRules: officeRules);
  }
}
