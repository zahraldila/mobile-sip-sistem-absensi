import '../../domain/entities/validation_result.dart';

class ValidationPayloadModel {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? distance;
  final String? ssid;
  final String? bssid;
  final String timestamp;
  final String attendanceMode;
  final bool isValid;
  final String? failureReason;

  const ValidationPayloadModel({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distance,
    this.ssid,
    this.bssid,
    required this.timestamp,
    required this.attendanceMode,
    required this.isValid,
    this.failureReason,
  });

  factory ValidationPayloadModel.fromEntity(ValidationResult result) {
    return ValidationPayloadModel(
      latitude: result.latitude,
      longitude: result.longitude,
      accuracy: result.accuracy,
      distance: result.distance,
      ssid: result.ssid,
      bssid: result.bssid,
      timestamp: result.timestamp.toIso8601String(),
      attendanceMode: result.attendanceMode,
      isValid: result.isValid,
      failureReason: result.failureReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'distance': distance,
      'ssid': ssid,
      'bssid': bssid,
      'timestamp': timestamp,
      'attendance_mode': attendanceMode,
      'is_valid': isValid,
      if (failureReason != null) 'failure_reason': failureReason,
    };
  }

  factory ValidationPayloadModel.fromJson(Map<String, dynamic> json) {
    return ValidationPayloadModel(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      ssid: json['ssid'] as String?,
      bssid: json['bssid'] as String?,
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      attendanceMode: json['attendance_mode'] as String? ?? 'WFO',
      isValid: json['is_valid'] as bool? ?? false,
      failureReason: json['failure_reason'] as String?,
    );
  }
}
