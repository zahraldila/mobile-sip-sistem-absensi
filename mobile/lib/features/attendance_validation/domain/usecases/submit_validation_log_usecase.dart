import '../entities/validation_result.dart';
import '../repositories/attendance_validation_repository.dart';

class SubmitValidationLogUseCase {
  final AttendanceValidationRepository repository;

  SubmitValidationLogUseCase(this.repository);

  Future<bool> execute(ValidationResult result) async {
    return await repository.submitValidationLog(result);
  }
}
