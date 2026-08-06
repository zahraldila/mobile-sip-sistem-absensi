import '../../domain/entities/validation_failure.dart';
import '../../domain/entities/validation_result.dart';
import '../../domain/entities/validation_step_status.dart';

class ValidationResultModel extends ValidationResult {
  const ValidationResultModel({
    required super.isValid,
    super.failure,
    super.latitude,
    super.longitude,
    super.accuracy,
    super.distance,
    super.ssid,
    super.bssid,
    required super.timestamp,
    super.stepDetails = const {},
    super.attendanceMode = 'WFO',
  });

  factory ValidationResultModel.fromJson(Map<String, dynamic> json) {
    ValidationFailure? failure;
    final failureStr = json['failure_reason'] as String?;
    if (failureStr != null && failureStr.isNotEmpty) {
      failure = UnknownValidationFailure(
        error: failureStr,
        message: failureStr,
      );
    }

    final stepDetailsJson = json['step_details'] as Map<String, dynamic>?;
    final Map<String, ValidationStepStatus> stepDetails = {};
    if (stepDetailsJson != null) {
      stepDetailsJson.forEach((key, value) {
        stepDetails[key] = ValidationStepStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toString().toLowerCase(),
          orElse: () => ValidationStepStatus.idle,
        );
      });
    }

    return ValidationResultModel(
      isValid: json['is_valid'] as bool? ?? false,
      failure: failure,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      ssid: json['ssid'] as String?,
      bssid: json['bssid'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      stepDetails: stepDetails,
      attendanceMode: json['attendance_mode'] as String? ?? 'WFO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_valid': isValid,
      'failure_reason': failureReason,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'distance': distance,
      'ssid': ssid,
      'bssid': bssid,
      'timestamp': timestamp.toIso8601String(),
      'attendance_mode': attendanceMode,
      'step_details': stepDetails.map((k, v) => MapEntry(k, v.name)),
    };
  }

  factory ValidationResultModel.fromEntity(ValidationResult entity) {
    return ValidationResultModel(
      isValid: entity.isValid,
      failure: entity.failure,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      distance: entity.distance,
      ssid: entity.ssid,
      bssid: entity.bssid,
      timestamp: entity.timestamp,
      stepDetails: entity.stepDetails,
      attendanceMode: entity.attendanceMode,
    );
  }
}
