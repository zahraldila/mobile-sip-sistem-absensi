import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';

class AttendanceService {
  AttendanceService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: SupabaseConfig.url,
              ),
            );

  final Dio _dio;

  /// Membangun request options dengan menyertakan token autentikasi jika tersedia.
  Future<Options> _buildOptions() async {
    final token = AuthState.instance.currentUser?.accessToken;
    return Options(
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${token != null && token.isNotEmpty ? token : SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  /// Mengambil jadwal kerja hari ini yang aktif.
  Future<Map<String, dynamic>?> fetchTodaySchedule() async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final options = await _buildOptions();
      var response = await _dio.get(
        '/rest/v1/jadwal_kerja',
        queryParameters: {
          'tanggal_berlaku': 'lte.$todayStr',
          'order': 'tanggal_berlaku.desc',
          'limit': '1',
        },
        options: options,
      );
      debugPrint('[AttendanceService] fetchTodaySchedule (lte) status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        return (response.data as List).first as Map<String, dynamic>;
      }

      // Fallback: Jika tidak ada jadwal yang <= hari ini (misal untuk testing data masa depan),
      // ambil jadwal pertama yang ada di database.
      response = await _dio.get(
        '/rest/v1/jadwal_kerja',
        queryParameters: {
          'limit': '1',
        },
        options: options,
      );
      debugPrint('[AttendanceService] fetchTodaySchedule (fallback) status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        return (response.data as List).first as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[AttendanceService] Error fetching schedule: $e');
    }
    return null;
  }

  /// Mengambil semua wifi kantor yang aktif.
  Future<List<Map<String, dynamic>>> fetchActiveOfficeWiFi() async {
    try {
      final options = await _buildOptions();
      final response = await _dio.get(
        '/rest/v1/wifi_kantor',
        queryParameters: {
          'aktif': 'eq.true',
        },
        options: options,
      );
      debugPrint('[AttendanceService] fetchActiveOfficeWiFi status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
    } catch (e) {
      debugPrint('[AttendanceService] Error fetching office WiFi: $e');
    }
    return [];
  }

  /// Mengambil data absensi hari ini milik pegawai.
  Future<Map<String, dynamic>?> fetchTodayAttendance(String pegawaiId) async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final options = await _buildOptions();
      final response = await _dio.get(
        '/rest/v1/absensi',
        queryParameters: {
          'pegawai_id': 'eq.$pegawaiId',
          'tanggal_absensi': 'eq.$todayStr',
          'limit': '1',
        },
        options: options,
      );
      debugPrint('[AttendanceService] fetchTodayAttendance status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        return (response.data as List).first as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[AttendanceService] Error fetching today attendance: $e');
    }
    return null;
  }

  /// Mengambil pengajuan yang disetujui (Disetujui) untuk hari ini.
  Future<Map<String, dynamic>?> fetchTodayApprovedSubmission(String pegawaiId) async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final options = await _buildOptions();
      final response = await _dio.get(
        '/rest/v1/pengajuan',
        queryParameters: {
          'pegawai_id': 'eq.$pegawaiId',
          'tanggal_pengajuan': 'eq.$todayStr',
          'status_pengajuan': 'eq.Disetujui',
          'limit': '1',
        },
        options: options,
      );
      debugPrint('[AttendanceService] fetchTodayApprovedSubmission status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        return (response.data as List).first as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[AttendanceService] Error fetching today approved submission: $e');
    }
    return null;
  }

  /// Melakukan check-in (insert ke tabel absensi).
  Future<void> checkIn({
    required String pegawaiId,
    required String skemaKerja,
    int? jadwalId,
    double? latitude,
    double? longitude,
    String? fotoSelfie,
    String? catatan,
    String? statusKehadiran,
  }) async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final nowIso = DateTime.now().toIso8601String();

      int? resolvedJadwalId = jadwalId;
      if (resolvedJadwalId == null) {
        final schedule = await fetchTodaySchedule();
        if (schedule != null) {
          resolvedJadwalId = int.tryParse(schedule['jadwal_id']?.toString() ?? '');
        }
      }

      final data = {
        'pegawai_id': int.tryParse(pegawaiId) ?? pegawaiId,
        'tanggal_absensi': todayStr,
        'jam_checkin': nowIso,
        'skema_kerja': skemaKerja,
        'status_kehadiran': statusKehadiran ?? 'Hadir',
        'jadwal_id': ?resolvedJadwalId,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'foto_selfie': ?fotoSelfie,
        'catatan': ?catatan,
      };

      final options = await _buildOptions();
      options.headers?['Prefer'] = 'return=minimal';

      final response = await _dio.post(
        '/rest/v1/absensi',
        data: data,
        options: options,
      );

      if (response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AttendanceService] Error during checkIn: $e');
      rethrow;
    }
  }

  /// Melakukan check-out (update baris absensi hari ini).
  Future<void> checkOut({
    required String pegawaiId,
    String? catatan,
  }) async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final nowIso = DateTime.now().toIso8601String();

      final data = {
        'jam_checkout': nowIso,
        'catatan': ?catatan,
      };

      final options = await _buildOptions();

      final response = await _dio.patch(
        '/rest/v1/absensi',
        queryParameters: {
          'pegawai_id': 'eq.$pegawaiId',
          'tanggal_absensi': 'eq.$todayStr',
        },
        data: data,
        options: options,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AttendanceService] Error during checkOut: $e');
      rethrow;
    }
  }
}
