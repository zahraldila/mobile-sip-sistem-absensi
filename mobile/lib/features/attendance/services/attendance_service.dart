import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/core/services/audit_log_service.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/services/activity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AttendanceService {
  AttendanceService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: SupabaseConfig.url,
              ),
            );

  final Dio _dio;

  /// Membangun request dengan sesi Supabase yang benar-benar aktif.
  ///
  /// Jangan gunakan token cache dari login aplikasi sendiri: token kedaluwarsa
  /// akan membuat PostgREST menolak request dengan 401, bahkan saat policy RLS
  /// memberi akses kepada role `anon`/`public`.
  Future<Options> _buildOptions() async {
    String? token;

    // Prioritaskan sesi SDK Supabase: token ini dapat diperbarui otomatis
    // ketika access token lama telah kedaluwarsa.
    try {
      final session = await supabase.Supabase.instance.client.auth.getSession();
      token = session?.accessToken;
    } catch (_) {
      token = supabase.Supabase.instance.client.auth.currentSession?.accessToken;
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

  /// Memastikan UID kartu NFC terdaftar untuk pegawai yang sedang absen.
  ///
  /// Tabel `nfc` menyimpan nomor kartu pada `nfc_serial_number`. Pemisah
  /// pembacaan Android (misalnya `:`) diabaikan agar cocok dengan data lama
  /// yang dapat memakai pemisah lain seperti `#`.
  Future<bool> validateNfcForPegawai({
    required String pegawaiId,
    required String uid,
  }) async {
    try {
      final normalizedPegawaiId = pegawaiId.trim();
      final pegawaiIdInt = int.tryParse(normalizedPegawaiId);
      final options = await _buildOptions();
      final response = await _dio.get(
        '/rest/v1/nfc',
        queryParameters: {
          'select': 'nfc_id,pegawai_id,nfc_serial_number',
          'pegawai_id': 'eq.${pegawaiIdInt ?? normalizedPegawaiId}',
        },
        options: options,
      );

      if (response.statusCode != 200 || response.data is! List) {
        throw Exception('Server tidak dapat memvalidasi kartu NFC.');
      }

      final scannedUid = _normalizeNfcSerial(uid);
      final records = List<Map<String, dynamic>>.from(response.data as List);
      return records.any((record) {
        final registeredUid = record['nfc_serial_number']?.toString() ?? '';
        return registeredUid.isNotEmpty &&
            _normalizeNfcSerial(registeredUid) == scannedUid;
      });
    } on DioException catch (error) {
      debugPrint(
        '[AttendanceService] NFC validation error: '
        '${error.response?.statusCode} ${error.response?.data ?? error.message}',
      );
      if (error.response?.statusCode == 401) {
        throw const AttendanceAuthenticationException();
      }
      rethrow;
    }
  }

  String _normalizeNfcSerial(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-F0-9]'), '');

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
      // Minta Supabase REST untuk mengembalikan baris yang baru dibuat sehingga
      // aplikasi bisa langsung memproses respons tanpa perlu polling panjang.
      options.headers?['Prefer'] = 'return=representation';

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

      // Supabase biasanya mengembalikan 201 dengan body ketika `Prefer: return=representation`.
      if (response.statusCode != 201 && response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      // Jika server mengembalikan representasi baris yang baru dibuat, tampilkan debug
      if (response.data != null) {
        try {
          debugPrint('[AttendanceService] checkIn created record: ${response.data}');
        } catch (_) {}
      }

      // Catat ke audit_log
      final aktivitas = await AuditLogService.instance.log('Check In');
      if (aktivitas != null) {
        ActivityService.instance.recordAuditActivity(aktivitas);
      }
    } on DioException catch (e) {
      debugPrint('[AttendanceService] DioException during checkIn: ${e.response?.statusCode} ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401) {
        throw const AttendanceAuthenticationException();
      }
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
    double? latitude,
    double? longitude,
  }) async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final nowIso = DateTime.now().toIso8601String();

      final data = {
        'jam_checkout': nowIso,
        'catatan': catatan,
        if (latitude != null) 'latitude_checkout': latitude,
        if (longitude != null) 'longitude_checkout': longitude,
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

      // Catat ke audit_log
      final aktivitas = await AuditLogService.instance.log('Check Out');
      if (aktivitas != null) {
        ActivityService.instance.recordAuditActivity(aktivitas);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AttendanceAuthenticationException();
      }
      debugPrint('[AttendanceService] Error during checkOut: $e');
      rethrow;
    } catch (e) {
      debugPrint('[AttendanceService] Error during checkOut: $e');
      rethrow;
    }
  }
}

class AttendanceAuthenticationException implements Exception {
  const AttendanceAuthenticationException();

  @override
  String toString() =>
      'Sesi login Supabase tidak valid atau sudah berakhir. Silakan logout lalu login kembali.';
}
