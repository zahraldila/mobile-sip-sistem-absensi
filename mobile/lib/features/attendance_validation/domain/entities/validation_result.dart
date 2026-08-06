import 'package:equatable/equatable.dart';
import 'validation_failure.dart';
import 'validation_step_status.dart';

class ValidationResult extends Equatable {
  final bool isValid;
  final ValidationFailure? failure;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? distance;
  final String? ssid;
  final String? bssid;
  final DateTime timestamp;
  final Map<String, ValidationStepStatus> stepDetails;
  final String attendanceMode;

  const ValidationResult({
    required this.isValid,
    this.failure,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distance,
    this.ssid,
    this.bssid,
    required this.timestamp,
    this.stepDetails = const {},
    this.attendanceMode = 'WFO',
  });

  /// Quick helper: formatted failure reason
  String? get failureReason => failure?.message;

  /// Quick helper: actionable hint for failure
  String? get actionHint => failure?.actionHint;

  /// Factory for successful validation result
  factory ValidationResult.success({
    required double latitude,
    required double longitude,
    required double accuracy,
    double? distance,
    String? ssid,
    String? bssid,
    required DateTime timestamp,
    Map<String, ValidationStepStatus> stepDetails = const {},
    String attendanceMode = 'WFO',
  }) {
    return ValidationResult(
      isValid: true,
      failure: null,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distance: distance,
      ssid: ssid,
      bssid: bssid,
      timestamp: timestamp,
      stepDetails: stepDetails,
      attendanceMode: attendanceMode,
    );
  }

  /// Factory for failed validation result
  factory ValidationResult.failed({
    required ValidationFailure failure,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? distance,
    String? ssid,
    String? bssid,
    DateTime? timestamp,
    Map<String, ValidationStepStatus> stepDetails = const {},
    String attendanceMode = 'WFO',
  }) {
    return ValidationResult(
      isValid: false,
      failure: failure,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distance: distance,
      ssid: ssid,
      bssid: bssid,
      timestamp: timestamp ?? DateTime.now(),
      stepDetails: stepDetails,
      attendanceMode: attendanceMode,
    );
  }

  ValidationResult copyWith({
    bool? isValid,
    ValidationFailure? failure,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? distance,
    String? ssid,
    String? bssid,
    DateTime? timestamp,
    Map<String, ValidationStepStatus>? stepDetails,
    String? attendanceMode,
  }) {
    return ValidationResult(
      isValid: isValid ?? this.isValid,
      failure: failure ?? this.failure,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      distance: distance ?? this.distance,
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      timestamp: timestamp ?? this.timestamp,
      stepDetails: stepDetails ?? this.stepDetails,
      attendanceMode: attendanceMode ?? this.attendanceMode,
    );
  }

  @override
  List<Object?> get props => [
        isValid,
        failure,
        latitude,
        longitude,
        accuracy,
        distance,
        ssid,
        bssid,
        timestamp,
        stepDetails,
        attendanceMode,
      ];
}
