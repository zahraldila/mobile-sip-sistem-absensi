import 'dart:async';
import '../../services/gps_service.dart';
import '../entities/validation_failure.dart';
import '../entities/validation_step_status.dart';
import 'attendance_validator_strategy.dart';

class GpsValidatorStrategy implements AttendanceValidatorStrategy {
  final GpsService gpsService;

  GpsValidatorStrategy({required this.gpsService});

  @override
  String get stepKey => 'gps';

  @override
  String get displayName => 'Layanan GPS & Koordinat';

  @override
  Future<ValidationStepResult> validate(ValidationContext context) async {
    if (!context.config.requireGps) {
      context.stepDetails[stepKey] = ValidationStepStatus.skipped;
      return const ValidationStepResult.skipped();
    }

    context.stepDetails[stepKey] = ValidationStepStatus.running;

    try {
      // 1. Check if GPS / Location service is enabled
      final isEnabled = await gpsService.isLocationServiceEnabled();
      if (!isEnabled) {
        context.stepDetails[stepKey] = ValidationStepStatus.failed;
        const failure = GpsDisabledFailure();
        context.failure = failure;
        return const ValidationStepResult.failed(failure);
      }

      context.isGpsEnabled = true;

      // 2. Fetch current coordinates with timeout
      final position = await gpsService.getCurrentPosition(
        timeLimit: context.config.locationTimeout,
      );

      context.latitude = position.latitude;
      context.longitude = position.longitude;
      context.accuracy = position.accuracy;

      context.stepDetails[stepKey] = ValidationStepStatus.passed;
      return const ValidationStepResult.passed();
    } on TimeoutException {
      // Try fallback to last known position
      final lastPos = await gpsService.getLastKnownPosition();
      if (lastPos != null) {
        context.latitude = lastPos.latitude;
        context.longitude = lastPos.longitude;
        context.accuracy = lastPos.accuracy;
        context.stepDetails[stepKey] = ValidationStepStatus.passed;
        return const ValidationStepResult.passed();
      }

      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      const failure = LocationFetchTimeoutFailure();
      context.failure = failure;
      return const ValidationStepResult.failed(failure);
    } catch (e) {
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      final failure = LocationFetchErrorFailure(details: e.toString());
      context.failure = failure;
      return ValidationStepResult.failed(failure);
    }
  }
}
