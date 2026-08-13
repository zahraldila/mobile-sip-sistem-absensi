import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_session_service.dart';

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
    String? token = AuthState.instance.currentUser?.accessToken;
    if (token == null || token.isEmpty) {
      try {
        final session = await supabase.Supabase.instance.client.auth.getSession();
        token = session?.accessToken;
      } catch (_) {
        token = supabase.Supabase.instance.client.auth.currentSession?.accessToken;
      }
    }
    if (token == null || token.isEmpty) {
      token = await AuthSessionService().restoreToken();
    }
    final headers = <String, dynamic>{
      'apikey': SupabaseConfig.anonKey,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(
      headers: headers,
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
      // Normalize date to local and format as DATE string matching DB `tanggal_absensi` column.
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      // Normalize pegawaiId: trim and prefer integer form when possible to match DB type.
      final normalizedPegawaiId = pegawaiId.trim();
      final pegawaiIdInt = int.tryParse(normalizedPegawaiId);
      final options = await _buildOptions();
      final queryParameters = {
        'pegawai_id': pegawaiIdInt != null ? 'eq.$pegawaiIdInt' : 'eq.$normalizedPegawaiId',
        'tanggal_absensi': 'eq.$todayStr',
        'order': 'absensi_id.desc',
        'limit': '1',
      };

      debugPrint('[AttendanceService] fetchTodayAttendance query: $queryParameters');

      final response = await _dio.get(
        '/rest/v1/absensi',
        queryParameters: queryParameters,
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
      // Guard: Cegah duplicate check-in jika pegawai sudah memiliki record check-in hari ini
      final existingAttendance = await fetchTodayAttendance(pegawaiId);
      if (existingAttendance != null) {
        final existingCheckIn = existingAttendance['jam_checkin']?.toString();
        if (existingCheckIn != null && existingCheckIn.isNotEmpty) {
          debugPrint('[AttendanceService] Prevented duplicate check-in for pegawai_id: $pegawaiId');
          throw Exception('Anda sudah melakukan check-in hari ini.');
        }
      }

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
        'jadwal_id': resolvedJadwalId,
        'latitude': latitude,
        'longitude': longitude,
        'foto_selfie': fotoSelfie,
        'catatan': catatan,
      };

      final options = await _buildOptions();
      options.headers?['Prefer'] = 'return=minimal';

      debugPrint('[AttendanceService] checkIn payload: pegawai_id=${data['pegawai_id']}, tanggal_absensi=${data['tanggal_absensi']}, jam_checkin=${data['jam_checkin']}, skema_kerja=${data['skema_kerja']}, status_kehadiran=${data['status_kehadiran']}, jadwal_id=${data['jadwal_id']}, latitude=${data['latitude']}, longitude=${data['longitude']}, foto_selfie=${data['foto_selfie']}, catatan=${data['catatan']}');

      final response = await _dio.post(
        '/rest/v1/absensi',
        data: data,
        options: options,
      );

      if (response.statusCode == 401) {
        // Log controlled details to help diagnose auth issues (do not print token)
        debugPrint('[AttendanceService] CheckIn 401 -> uri=${response.realUri}');
        debugPrint('[AttendanceService] CheckIn 401 -> status=${response.statusCode}, body=${response.data}');
        final loggedHeaders = Map<String, dynamic>.from(options.headers ?? {});
        if (loggedHeaders.containsKey('Authorization')) {
          loggedHeaders['Authorization'] = 'Bearer [REDACTED]';
        }
        debugPrint('[AttendanceService] CheckIn 401 -> request headers=$loggedHeaders');
        throw Exception('Unauthorized (401) during checkIn');
      }

      if (response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[AttendanceService] DioException during checkIn: ${e.response?.statusCode} ${e.response?.data ?? e.message}');
      rethrow;
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
        'catatan': catatan,
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
