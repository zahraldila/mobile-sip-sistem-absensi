import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';

/// Service terpusat untuk mencatat aktivitas pegawai ke tabel [audit_log].
///
/// Tabel [audit_log] memiliki kolom:
///   - log_id    : primary key (auto-generated)
///   - akun_id   : id akun pegawai yang melakukan aksi
///   - aktivitas : deskripsi singkat aksi yang dilakukan
///   - waktu_log : timestamp waktu aksi
///
/// Gunakan [log] untuk mencatat aksi. Metode ini bersifat *fire-and-forget*:
/// tidak pernah melempar exception dan tidak memblokir caller.
class AuditLogService {
  AuditLogService._();

  static final AuditLogService instance = AuditLogService._();

  /// Mencatat aktivitas pegawai ke tabel [audit_log] di Supabase.
  ///
  /// Dipanggil tanpa [await] dari sisi caller agar tidak memblokir alur utama.
  /// Jika terjadi error (misal: tidak ada koneksi), error hanya di-log ke console
  /// dan tidak dilempar ke caller.
  Future<String?> log(String aktivitas) async {
    try {
      final user = AuthState.instance.currentUser;
      final akunId = user?.akunId ?? '';

      if (akunId.isEmpty) {
        debugPrint('[AuditLogService] Skipped: akunId tidak tersedia untuk aktivitas "$aktivitas"');
        return null;
      }

      final namaPegawai = user?.namaPegawai ?? '';
      final nama = namaPegawai.isNotEmpty ? namaPegawai : (user?.username ?? 'Pengguna');
      final aktivitasLengkap = '$nama melakukan $aktivitas';

      final token = user?.accessToken ?? '';
      final dio = Dio(
        BaseOptions(
          baseUrl: SupabaseConfig.url,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${token.isNotEmpty ? token : SupabaseConfig.anonKey}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Prefer': 'return=minimal',
          },
        ),
      );

      final resolvedAkunId = int.tryParse(akunId) ?? akunId;
      final response = await dio.post(
        '/rest/v1/audit_log',
        data: {
          'akun_id': resolvedAkunId,
          'aktivitas': aktivitasLengkap,
          'waktu_log': DateTime.now().toUtc().toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 204) {
        debugPrint('[AuditLogService] Dicatat: "$aktivitasLengkap" (akun_id=$akunId)');
        return aktivitasLengkap;
      } else {
        debugPrint('[AuditLogService] Gagal catat "$aktivitasLengkap": status=${response.statusCode}, body=${response.data}');
        return null;
      }
    } catch (e) {
      // Tidak melempar error agar tidak mengganggu alur utama aplikasi.
      debugPrint('[AuditLogService] Exception saat catat "$aktivitas": $e');
      return null;
    }
  }
}