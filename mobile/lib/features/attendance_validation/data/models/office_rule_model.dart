import '../../domain/entities/office_rule.dart';

class OfficeRuleModel extends OfficeRule {
  const OfficeRuleModel({
    required super.id,
    required super.officeName,
    required super.latitude,
    required super.longitude,
    super.maxRadiusMeters = 50.0,
    super.allowedSsids = const ['SIP-Office-WiFi', 'SIP-HQ-5G', 'SELADA-WIFI', 'SIP-Guest-Secure'],
    super.allowedBssids = const [],
    super.isWifiRequired = true,
    super.isGpsRequired = true,
  });

  factory OfficeRuleModel.fromJson(Map<String, dynamic> json) {
    // Handle nested or separate wifi_kantor list from Supabase
    final ssids = <String>[];
    final bssids = <String>[];

    final rawWifi = json['wifi_kantor'];
    if (rawWifi is List) {
      for (final item in rawWifi) {
        if (item is Map<String, dynamic>) {
          final isAktif = item['aktif'] as bool? ?? true;
          if (isAktif) {
            final ssid = item['ssid'] as String?;
            final bssid = item['bssid'] as String?;
            if (ssid != null && ssid.trim().isNotEmpty) {
              ssids.add(ssid.trim());
            }
            if (bssid != null && bssid.trim().isNotEmpty) {
              bssids.add(bssid.trim());
            }
          }
        }
      }
    } else if (json['allowed_ssids'] is List) {
      ssids.addAll(
        (json['allowed_ssids'] as List)
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty),
      );
    }

    if (json['allowed_bssids'] is List) {
      bssids.addAll(
        (json['allowed_bssids'] as List)
            .map((e) => e.toString())
            .where((b) => b.isNotEmpty),
      );
    }

    return OfficeRuleModel(
      id: (json['lokasi_id'] ?? json['id'] ?? '1').toString(),
      officeName: json['nama_kantor'] as String? ??
          json['office_name'] as String? ??
          'Kantor',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -6.910194028769816,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 107.65072801284482,
      maxRadiusMeters: (json['radius_meter'] as num?)?.toDouble() ??
          (json['max_radius_meters'] as num?)?.toDouble() ??
          50.0,
      allowedSsids: ssids.isNotEmpty ? ssids : const ['SIP-Office-WiFi'],
      allowedBssids: bssids,
      isWifiRequired: json['is_wifi_required'] as bool? ?? true,
      isGpsRequired: json['is_gps_required'] as bool? ?? true,
    );
  }

  factory OfficeRuleModel.fromSupabase({
    required Map<String, dynamic> lokasiJson,
    List<dynamic>? wifiList,
  }) {
    final copy = Map<String, dynamic>.from(lokasiJson);
    if (wifiList != null) {
      copy['wifi_kantor'] = wifiList;
    }
    return OfficeRuleModel.fromJson(copy);
  }

  Map<String, dynamic> toJson() {
    return {
      'lokasi_id': id,
      'nama_kantor': officeName,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': maxRadiusMeters,
      'allowed_ssids': allowedSsids,
      'allowed_bssids': allowedBssids,
      'is_wifi_required': isWifiRequired,
      'is_gps_required': isGpsRequired,
    };
  }

  factory OfficeRuleModel.fromEntity(OfficeRule entity) {
    return OfficeRuleModel(
      id: entity.id,
      officeName: entity.officeName,
      latitude: entity.latitude,
      longitude: entity.longitude,
      maxRadiusMeters: entity.maxRadiusMeters,
      allowedSsids: entity.allowedSsids,
      allowedBssids: entity.allowedBssids,
      isWifiRequired: entity.isWifiRequired,
      isGpsRequired: entity.isGpsRequired,
    );
  }
}
