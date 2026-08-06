import 'package:equatable/equatable.dart';
import 'office_rule.dart';

class ValidationConfig extends Equatable {
  final String attendanceMode; // 'WFO', 'WFH', 'WFC'
  final bool requirePermission;
  final bool requireGps;
  final bool requireDistance;
  final bool requireWifi;
  final OfficeRule? customOfficeRule;
  final Duration locationTimeout;

  const ValidationConfig({
    this.attendanceMode = 'WFO',
    this.requirePermission = true,
    this.requireGps = true,
    this.requireDistance = true,
    this.requireWifi = true,
    this.customOfficeRule,
    this.locationTimeout = const Duration(seconds: 10),
  });

  /// Factory for WFO (Work From Office): requires permission, GPS, distance, and Wi-Fi
  factory ValidationConfig.wfo({OfficeRule? officeRule}) {
    return ValidationConfig(
      attendanceMode: 'WFO',
      requirePermission: true,
      requireGps: true,
      requireDistance: true,
      requireWifi: true,
      customOfficeRule: officeRule,
    );
  }

  /// Factory for WFH (Work From Home): requires permission & GPS, but not office Wi-Fi / office radius
  factory ValidationConfig.wfh({OfficeRule? officeRule}) {
    return ValidationConfig(
      attendanceMode: 'WFH',
      requirePermission: true,
      requireGps: true,
      requireDistance: false,
      requireWifi: false,
      customOfficeRule: officeRule,
    );
  }

  /// Factory for WFC (Work From Client): requires permission & GPS
  factory ValidationConfig.wfc({OfficeRule? officeRule}) {
    return ValidationConfig(
      attendanceMode: 'WFC',
      requirePermission: true,
      requireGps: true,
      requireDistance: false,
      requireWifi: false,
      customOfficeRule: officeRule,
    );
  }

  @override
  List<Object?> get props => [
        attendanceMode,
        requirePermission,
        requireGps,
        requireDistance,
        requireWifi,
        customOfficeRule,
        locationTimeout,
      ];
}
