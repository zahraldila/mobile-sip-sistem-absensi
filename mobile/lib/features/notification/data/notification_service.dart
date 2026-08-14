import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import '../domain/models/notification_model.dart';

/// Service untuk mengambil data notifikasi dari Supabase.
///
/// Menggunakan [Dio] (konsisten dengan [AuthService]).
/// Data diambil dari tabel [notifikasi] dan difilter berdasarkan [pegawaiId].
class NotificationService {
  NotificationService({Dio? dio})
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

  final Dio _dio;

  /// Mengambil semua notifikasi milik [pegawaiId], diurutkan terbaru dulu.
  Future<List<NotificationModel>> fetchNotifications(String pegawaiId) async {
    try {
      final token = AuthState.instance.currentUser?.accessToken;
      final resolvedPegawaiId = int.tryParse(pegawaiId) ?? pegawaiId;

      final response = await _dio.get(
        '/rest/v1/notifikasi',
        queryParameters: {
          'pegawai_id': 'eq.$resolvedPegawaiId',
          'order': 'notifikasi_id.desc',
        },
        options: Options(
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${token != null && token.isNotEmpty ? token : SupabaseConfig.anonKey}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List<dynamic>;
        return list
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return const [];
    } on DioException catch (e) {
      debugPrint('[NotificationService] Error: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }
}
