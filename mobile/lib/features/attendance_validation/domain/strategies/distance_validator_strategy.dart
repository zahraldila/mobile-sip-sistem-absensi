import '../../services/distance_calculator_service.dart';
import '../entities/office_rule.dart';
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
      context.isDistanceValid = false;
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      const failure = LocationFetchErrorFailure(
        details: 'Koordinat lokasi pengguna tidak ditemukan.',
        message: 'Tidak dapat menghitung jarak karena koordinat lokasi kosong.',
      );
      context.failure = failure;
      return const ValidationStepResult.failed(failure);
    }

    final offices = context.officeRules.isNotEmpty
        ? context.officeRules
        : [context.officeRule];

    OfficeRule? matchingOffice;
    OfficeRule? nearestOffice;
    double? minDistance;

    for (final office in offices) {
      final dist = distanceCalculatorService.calculateDistance(
        userLat,
        userLng,
        office.latitude,
        office.longitude,
      );

      if (minDistance == null || dist < minDistance) {
        minDistance = dist;
        nearestOffice = office;
      }

      if (dist <= office.maxRadiusMeters) {
        matchingOffice = office;
        minDistance = dist;
        break;
      }
    }

    final effectiveDistance = minDistance ?? 0.0;
    context.distance = effectiveDistance;

    if (matchingOffice != null) {
      context.isDistanceValid = true;
      context.matchedOfficeRule = matchingOffice;
      context.stepDetails[stepKey] = ValidationStepStatus.passed;
      return const ValidationStepResult.passed();
    }

    context.isDistanceValid = false;
    context.matchedOfficeRule ??= nearestOffice;
    context.stepDetails[stepKey] = ValidationStepStatus.failed;

    final maxRadius = nearestOffice?.maxRadiusMeters ?? 50.0;
    final nearestOfficeName = nearestOffice?.officeName ?? 'kantor';

    final failure = OutOfRadiusFailure(
      currentDistance: double.parse(effectiveDistance.toStringAsFixed(1)),
      maxAllowedRadius: maxRadius,
      message:
          'Jarak Anda (${effectiveDistance.toStringAsFixed(1)}m) berada di luar batas radius $nearestOfficeName (${maxRadius.toStringAsFixed(0)}m).',
      actionHint: 'Silakan mendekat ke area kantor untuk melakukan absensi.',
    );
    context.failure = failure;

    // In WFO (where requireWifi is also true), allow Wi-Fi validation to run (shouldHalt = false)
    return ValidationStepResult.failed(
      failure,
      shouldHalt: !context.config.requireWifi,
    );
  }
}
