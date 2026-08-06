import '../../services/distance_calculator_service.dart';
import '../entities/validation_failure.dart';
import '../entities/validation_step_status.dart';
import 'attendance_validator_strategy.dart';

class DistanceValidatorStrategy implements AttendanceValidatorStrategy {
  final DistanceCalculatorService distanceCalculatorService;

  DistanceValidatorStrategy({required this.distanceCalculatorService});

  @override
  String get stepKey => 'distance';

  @override
  String get displayName => 'Radius Jarak ke Kantor';

  @override
  Future<ValidationStepResult> validate(ValidationContext context) async {
    if (!context.config.requireDistance) {
      context.stepDetails[stepKey] = ValidationStepStatus.skipped;
      return const ValidationStepResult.skipped();
    }

    context.stepDetails[stepKey] = ValidationStepStatus.running;

    final userLat = context.latitude;
    final userLng = context.longitude;

    if (userLat == null || userLng == null) {
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      const failure = LocationFetchErrorFailure(
        details: 'Koordinat lokasi pengguna tidak ditemukan.',
        message: 'Tidak dapat menghitung jarak karena koordinat lokasi kosong.',
      );
      context.failure = failure;
      return const ValidationStepResult.failed(failure);
    }

    final targetLat = context.officeRule.latitude;
    final targetLng = context.officeRule.longitude;
    final maxRadius = context.officeRule.maxRadiusMeters;

    final calculatedDistance = distanceCalculatorService.calculateDistance(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );

    context.distance = calculatedDistance;

    if (calculatedDistance > maxRadius) {
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      final failure = OutOfRadiusFailure(
        currentDistance: double.parse(calculatedDistance.toStringAsFixed(1)),
        maxAllowedRadius: maxRadius,
        message:
            'Jarak Anda (${calculatedDistance.toStringAsFixed(1)}m) berada di luar batas radius kantor (${maxRadius.toStringAsFixed(0)}m).',
        actionHint: 'Silakan mendekat ke area kantor untuk melakukan absensi.',
      );
      context.failure = failure;
      return ValidationStepResult.failed(failure);
    }

    context.stepDetails[stepKey] = ValidationStepStatus.passed;
    return const ValidationStepResult.passed();
  }
}
