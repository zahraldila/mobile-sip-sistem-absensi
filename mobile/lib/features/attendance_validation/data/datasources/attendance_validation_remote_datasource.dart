import 'dart:async';
import 'package:dio/dio.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import '../models/office_rule_model.dart';
import '../models/validation_payload_model.dart';

abstract class AttendanceValidationRemoteDataSource {
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
  Future<OfficeRuleModel> getOfficeRule() async {
    try {
      // 1. Query table lokasi_kantor beserta relasi wifi_kantor langsung dari Supabase
      final response = await _dio.get(
        '/rest/v1/lokasi_kantor',
        queryParameters: {
          'select': '*,wifi_kantor(*)',
          'limit': '1',
        },
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (response.statusCode == 200 &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        final data = (response.data as List).first as Map<String, dynamic>;
        return OfficeRuleModel.fromJson(data);
      }

      // 2. Fallback jika relasi nested foreign-key belum diaktifkan di PostgREST:
      final lokasiRes = await _dio.get(
        '/rest/v1/lokasi_kantor',
        queryParameters: {'select': '*', 'limit': '1'},
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (lokasiRes.statusCode == 200 &&
          lokasiRes.data is List &&
          (lokasiRes.data as List).isNotEmpty) {
        final lokasiData = (lokasiRes.data as List).first as Map<String, dynamic>;
        final dynamic lokasiId = lokasiData['lokasi_id'];

        final wifiRes = await _dio.get(
          '/rest/v1/wifi_kantor',
          queryParameters: {
            'select': '*',
            if (lokasiId != null) 'lokasi_id': 'eq.$lokasiId',
            'aktif': 'eq.true',
          },
          options: Options(validateStatus: (status) => status != null && status < 500),
        );

        final wifiList = (wifiRes.statusCode == 200 && wifiRes.data is List)
            ? (wifiRes.data as List)
            : null;

        return OfficeRuleModel.fromSupabase(
          lokasiJson: lokasiData,
          wifiList: wifiList,
        );
      }
    } catch (_) {
      // Graceful fallback to default rule if offline
    }

    // Default development fallback jika database belum terisi
    return const OfficeRuleModel(
      id: '1',
      officeName: 'Kantor',
      latitude: -6.910194028769816,
      longitude: 107.65072801284482,
      maxRadiusMeters: 50.0,
      allowedSsids: ['SIP-Office-WiFi', 'SELADA-WIFI'],
      allowedBssids: [],
      isWifiRequired: true,
      isGpsRequired: true,
    );
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
