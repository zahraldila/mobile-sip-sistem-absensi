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
}
