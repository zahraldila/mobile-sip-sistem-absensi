import 'dart:async';
import 'package:dio/dio.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import '../models/office_rule_model.dart';
import '../models/validation_payload_model.dart';

abstract class AttendanceValidationRemoteDataSource {
  Future<List<OfficeRuleModel>> getOfficeRules();
  Future<OfficeRuleModel> getOfficeRule();
  Future<bool> submitValidationTelemetry(ValidationPayloadModel payload);
}

class AttendanceValidationRemoteDataSourceImpl
    implements AttendanceValidationRemoteDataSource {
  final Dio _dio;

  AttendanceValidationRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: SupabaseConfig.url,
                headers: {
                  'apikey': SupabaseConfig.anonKey,
                  'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  @override
  Future<List<OfficeRuleModel>> getOfficeRules() async {
    try {
      // 1. Query table lokasi_kantor beserta relasi wifi_kantor langsung dari Supabase
      final response = await _dio.get(
        '/rest/v1/lokasi_kantor',
        queryParameters: {
          'select': '*,wifi_kantor(*)',
        },
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (response.statusCode == 200 &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        final list = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => OfficeRuleModel.fromJson(e))
            .toList();
        if (list.isNotEmpty) return list;
      }

      // 2. Fallback jika relasi nested foreign-key belum diaktifkan di PostgREST:
      final lokasiRes = await _dio.get(
        '/rest/v1/lokasi_kantor',
        queryParameters: {'select': '*'},
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (lokasiRes.statusCode == 200 &&
          lokasiRes.data is List &&
          (lokasiRes.data as List).isNotEmpty) {
        final wifiRes = await _dio.get(
          '/rest/v1/wifi_kantor',
          queryParameters: {
            'select': '*',
            'aktif': 'eq.true',
          },
          options: Options(validateStatus: (status) => status != null && status < 500),
        );

        final allWifiList = (wifiRes.statusCode == 200 && wifiRes.data is List)
            ? (wifiRes.data as List)
            : <dynamic>[];

        final List<OfficeRuleModel> resultList = [];
        for (final rawLokasi in (lokasiRes.data as List)) {
          if (rawLokasi is Map<String, dynamic>) {
            final dynamic lokasiId = rawLokasi['lokasi_id'] ?? rawLokasi['id'];
            final matchingWifis = allWifiList.where((w) {
              if (w is Map<String, dynamic>) {
                final wLokasiId = w['lokasi_id'];
                return wLokasiId == null ||
                    wLokasiId.toString() == lokasiId?.toString();
              }
              return false;
            }).toList();

            resultList.add(OfficeRuleModel.fromSupabase(
              lokasiJson: rawLokasi,
              wifiList: matchingWifis.isNotEmpty ? matchingWifis : null,
            ));
          }
        }

        if (resultList.isNotEmpty) {
          return resultList;
        }
      }
    } catch (_) {
      // Graceful fallback to default rule if offline
    }

    // Default development fallback jika database belum terisi / offline
    return const [
      OfficeRuleModel(
        id: '1',
        officeName: 'Kantor',
        latitude: -6.910194028769816,
        longitude: 107.65072801284482,
        maxRadiusMeters: 100.0,
        allowedSsids: ['SIP-Office-WiFi', 'SELADA-WIFI'],
        allowedBssids: [],
        isWifiRequired: true,
        isGpsRequired: true,
      ),
    ];
  }

  @override
  Future<OfficeRuleModel> getOfficeRule() async {
    final rules = await getOfficeRules();
    return rules.first;
  }

  @override
  Future<bool> submitValidationTelemetry(ValidationPayloadModel payload) async {
    try {
      final response = await _dio.post(
        '/rest/v1/audit_log',
        data: {
          'aktivitas':
              'Validasi Absensi (${payload.attendanceMode}): ${payload.isValid ? 'BERHASIL' : 'GAGAL'}',
          'waktu_log': payload.timestamp,
        },
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
