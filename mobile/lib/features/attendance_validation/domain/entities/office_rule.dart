import 'package:equatable/equatable.dart';

class OfficeRule extends Equatable {
  final String id;
  final String officeName;
  final double latitude;
  final double longitude;
  final double maxRadiusMeters;
  final List<String> allowedSsids;
  final List<String> allowedBssids;
  final bool isWifiRequired;
  final bool isGpsRequired;

  const OfficeRule({
    required this.id,
    required this.officeName,
    required this.latitude,
    required this.longitude,
    this.maxRadiusMeters = 50.0,
    this.allowedSsids = const ['SIP-Office-WiFi', 'SIP-HQ-5G', 'SELADA-WIFI', 'SIP-Guest-Secure'],
    this.allowedBssids = const [],
    this.isWifiRequired = true,
    this.isGpsRequired = true,
  });

  /// Default mock office rule for PT Selada / SIP Office
  factory OfficeRule.defaultOffice() {
    return const OfficeRule(
      id: 'OFFICE-HQ-001',
      officeName: 'Kantor Pusat PT Selada',
      latitude: -6.208800,
      longitude: 106.845600,
      maxRadiusMeters: 50.0,
      allowedSsids: ['SIP-Office-WiFi', 'SIP-HQ-5G', 'SELADA-WIFI', 'SIP-Guest-Secure'],
      allowedBssids: [],
      isWifiRequired: true,
      isGpsRequired: true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        officeName,
        latitude,
        longitude,
        maxRadiusMeters,
        allowedSsids,
        allowedBssids,
        isWifiRequired,
        isGpsRequired,
      ];
}
