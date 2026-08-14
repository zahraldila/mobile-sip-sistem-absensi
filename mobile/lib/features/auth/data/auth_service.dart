import 'dart:async';
import 'package:bcrypt/bcrypt.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/core/services/audit_log_service.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/services/activity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../domain/entities/auth_user.dart';
import '../services/auth_session_service.dart';

class AuthService {
  final Dio _dio;
  bool _loggedIn = false;
  String? lastErrorMessage;

  AuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: SupabaseConfig.url,
              headers: {
                'apikey': SupabaseConfig.anonKey,
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  Future<Options> _buildRequestOptions({
    bool preferRepresentation = false,
  }) async {
    final headers = <String, dynamic>{
      'apikey': SupabaseConfig.anonKey,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    String? sessionToken;
    try {
      final session = await supabase.Supabase.instance.client.auth.getSession();
      sessionToken = session?.accessToken;
    } catch (_) {
      sessionToken = supabase.Supabase.instance.client.auth.currentSession?.accessToken;
    }

    final token = sessionToken != null && sessionToken.isNotEmpty
        ? sessionToken
        : await AuthSessionService().restoreToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (preferRepresentation) {
      headers['Prefer'] = 'return=representation';
    }

    return Options(
      headers: headers,
      validateStatus: (status) => status != null && status < 500,
    );
  }

  Future<AuthUser?> login({
    required String identifier,
    required String password,
  }) async {
    lastErrorMessage = null;
    final normalizedIdentifier = identifier.trim();
    final normalizedPassword = password.trim();

    if (normalizedIdentifier.isEmpty || normalizedPassword.isEmpty) {
      lastErrorMessage = 'Email atau username tidak boleh kosong.';
      return null;
    }

    try {
      final path = '/rest/v1/akun';
      final usernameQuery = {
        'select': '*',
        'username': 'eq.$normalizedIdentifier',
        'limit': '1',
      };

      final usernameResponse = await _dio.get(
        path,
        queryParameters: usernameQuery,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('AUTH LOGIN username search path=$path query=$usernameQuery');
      debugPrint('AUTH LOGIN status=${usernameResponse.statusCode}');
      debugPrint('AUTH LOGIN body=${usernameResponse.data}');

      Map<String, dynamic>? rawAccount;

      if (usernameResponse.statusCode == 200 &&
          usernameResponse.data is List &&
          (usernameResponse.data as List).isNotEmpty) {
        final accountCandidate = (usernameResponse.data as List).first;
        if (accountCandidate is Map<String, dynamic>) {
          rawAccount = accountCandidate;
        }
      }

      if (rawAccount == null) {
        final pegawaiPath = '/rest/v1/pegawai';
        final pegawaiQuery = {
          'select': 'pegawai_id',
          'email': 'ilike.$normalizedIdentifier',
          'limit': '1',
        };

        final pegawaiResponse = await _dio.get(
          pegawaiPath,
          queryParameters: pegawaiQuery,
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        debugPrint('AUTH LOGIN email search path=$pegawaiPath query=$pegawaiQuery');
        debugPrint('AUTH LOGIN status=${pegawaiResponse.statusCode}');
        debugPrint('AUTH LOGIN body=${pegawaiResponse.data}');

        if (pegawaiResponse.statusCode == 200 &&
            pegawaiResponse.data is List &&
            (pegawaiResponse.data as List).isNotEmpty) {
          final pegawaiCandidate = (pegawaiResponse.data as List).first;
          if (pegawaiCandidate is Map<String, dynamic>) {
            final pegawaiId = pegawaiCandidate['pegawai_id']?.toString() ?? '';
            if (pegawaiId.isNotEmpty) {
              final accountByPegawaiQuery = {
                'select': '*',
                'pegawai_id': 'eq.$pegawaiId',
                'limit': '1',
              };

              final accountResponse = await _dio.get(
                path,
                queryParameters: accountByPegawaiQuery,
                options: Options(
                  validateStatus: (status) => status != null && status < 500,
                ),
              );

              debugPrint('AUTH LOGIN account by pegawai_id path=$path query=$accountByPegawaiQuery');
              debugPrint('AUTH LOGIN status=${accountResponse.statusCode}');
              debugPrint('AUTH LOGIN body=${accountResponse.data}');

              if (accountResponse.statusCode == 200 &&
                  accountResponse.data is List &&
                  (accountResponse.data as List).isNotEmpty) {
                final accountCandidate = (accountResponse.data as List).first;
                if (accountCandidate is Map<String, dynamic>) {
                  rawAccount = accountCandidate;
                }
              }
            }
          }
        }
      }

      if (rawAccount == null) {
        lastErrorMessage = 'Username atau email tidak ditemukan.';
        return null;
      }

      final storedPassword = rawAccount['password']?.toString() ?? '';
      if (storedPassword.isEmpty) {
        lastErrorMessage = 'Password akun tidak tersedia.';
        return null;
      }

      final role = rawAccount['role']?.toString().toLowerCase() ?? '';
      if (role != 'pegawai' && role != 'karyawan') {
        lastErrorMessage = 'Akun tidak memiliki akses mobile.';
        return null;
      }

      if (!_verifyPassword(normalizedPassword, storedPassword)) {
        lastErrorMessage = 'Username/email atau password salah.';
        return null;
      }

      final akunId = rawAccount['akun_id']?.toString() ?? '';
      final pegawaiId = rawAccount['pegawai_id']?.toString() ?? '';
      final username = rawAccount['username']?.toString() ?? '';

      Map<String, dynamic>? pegawaiData;
      if (pegawaiId.isNotEmpty) {
        pegawaiData = await getPegawaiDetail(pegawaiId);
      }

      final emailForSupabase = _resolveSupabaseAuthEmail(
        normalizedIdentifier: normalizedIdentifier,
        rawAccount: rawAccount,
        pegawaiData: pegawaiData,
      );

      String accessToken = '';
      if (emailForSupabase != null && emailForSupabase.isNotEmpty) {
        try {
          final authResponse = await supabase.Supabase.instance.client.auth.signInWithPassword(
            email: emailForSupabase,
            password: normalizedPassword,
          );

          final session = authResponse.session;
          if (session != null && session.accessToken.isNotEmpty) {
            accessToken = session.accessToken;
          } else {
            debugPrint('Supabase login succeeded without a session token. Continuing with custom auth.');
          }
        } catch (e) {
          debugPrint('Supabase login error: $e');
          debugPrint('Custom auth succeeded; skipping Supabase session because the account may not exist in Supabase Auth.');
        }
      } else {
        debugPrint('No Supabase auth email resolved. Continuing with custom auth only.');
      }

      _loggedIn = true;
      final authUser = AuthUser(
        akunId: akunId,
        pegawaiId: pegawaiId,
        username: username,
        role: rawAccount['role']?.toString() ?? '',
        namaPegawai: pegawaiData?['nama_pegawai']?.toString() ??
            pegawaiData?['namaPegawai']?.toString() ??
            '',
        email: pegawaiData?['email']?.toString() ?? '',
        jabatan: pegawaiData?['jabatan']?.toString() ?? '',
        divisi: pegawaiData?['divisi']?.toString() ?? '',
        fotoProfile: pegawaiData?['foto_profile']?.toString() ??
            pegawaiData?['fotoProfile']?.toString() ??
            '',
        accessToken: accessToken,
      );

      // Catat ke audit_log — akun_id diambil dari data yang baru di-resolve.
      // AuditLogService membaca dari AuthState, namun saat ini AuthState belum
      // di-set, jadi kita POST langsung menggunakan akunId yang sudah diketahui.
      final namaForLog = authUser.namaPegawai.isNotEmpty ? authUser.namaPegawai : authUser.username;
      await _logAuditLogin(akunId: akunId, nama: namaForLog, token: accessToken);

      return authUser;
    } on DioException catch (e) {
      debugPrint('ERROR');
      debugPrint('${e.response?.statusCode}');
      debugPrint('${e.response?.data}');
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    return _loggedIn;
  }

  Future<Map<String, dynamic>?> getPegawaiDetail(String pegawaiId) async {
    try {
      final path = '/rest/v1/pegawai';
      final queryParameters = {
        'pegawai_id': 'eq.$pegawaiId',
        'select': '*,master_divisi(nama_divisi),master_jabatan(nama_jabatan)',
      };
      final options = await _buildRequestOptions();
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      debugPrint('GET pegawai detail status=${response.statusCode}');
      debugPrint('GET pegawai detail uri=${response.realUri}');
      debugPrint('GET pegawai detail body=${response.data}');
      if (response.statusCode == 200 &&
          response.data is List &&
          response.data.isNotEmpty) {
        final rawDetail = response.data.first as Map<String, dynamic>;
        
        final divisiData = rawDetail['master_divisi'];
        final divisiName = divisiData is Map 
            ? divisiData['nama_divisi']?.toString() ?? ''
            : (divisiData is List && divisiData.isNotEmpty 
                ? (divisiData.first as Map)['nama_divisi']?.toString() ?? ''
                : '');

        final jabatanData = rawDetail['master_jabatan'];
        final jabatanName = jabatanData is Map 
            ? jabatanData['nama_jabatan']?.toString() ?? ''
            : (jabatanData is List && jabatanData.isNotEmpty 
                ? (jabatanData.first as Map)['nama_jabatan']?.toString() ?? ''
                : '');

        return {
          ...rawDetail,
          'divisi': divisiName,
          'jabatan': jabatanName,
        };
      }
    } catch (e) {
      debugPrint('Error fetching pegawai detail: $e');
    }
    return null;
  }

  Future<bool> updatePegawai(
    String pegawaiId,
    Map<String, dynamic> data,
  ) async {
    try {
      final path = '/rest/v1/pegawai';

      final queryParameters = {
        'pegawai_id': 'eq.$pegawaiId',
        'select': '*',
      };
      debugPrint('PATCH pegawai request path=$path');
      debugPrint('PATCH pegawai request query=$queryParameters');
      debugPrint('PATCH pegawai request payload=$data');
      final options = await _buildRequestOptions(preferRepresentation: true);
      debugPrint('PATCH pegawai request headers=${options.headers}');
      final response = await _dio.patch(
        path,
        queryParameters: queryParameters,
        data: data,
        options: options,
      );
      debugPrint('PATCH pegawai status=${response.statusCode}');
      debugPrint('PATCH pegawai uri=${response.realUri}');
      debugPrint('PATCH pegawai headers=${response.headers.map}');
      debugPrint('PATCH pegawai body=${response.data}');

      if (response.data is List) {
        debugPrint('PATCH pegawai affected_rows=${(response.data as List).length}');
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        return false;
      }

      bool success;
      if (response.data is List) {
        success = (response.data as List).isNotEmpty;
      } else {
        success = response.statusCode == 204 || response.data != null;
      }

      if (success) {
        // Catat ke audit_log & ActivityService
        AuditLogService.instance.log('Update data profil');
        ActivityService.instance.recordAuditActivity('Memperbarui informasi kontak profil');
      }

      return success;
    } catch (e) {
      debugPrint('ERROR UPDATE');
      debugPrint(e.toString());
      return false;
    }
  }

  /// Mencatat aksi login ke tabel [audit_log].
  /// Dipanggil secara terpisah saat login karena [AuthState] belum di-set
  /// pada saat metode [login] selesai dieksekusi.
  Future<void> _logAuditLogin({
    required String akunId,
    required String nama,
    required String token,
  }) async {
    try {
      if (akunId.isEmpty) return;

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

      await dio.post(
        '/rest/v1/audit_log',
        data: {
          'akun_id': akunId,
          'aktivitas': '$nama berhasil melakukan Login',
          'waktu_log': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('[AuditLogService] Dicatat: "$nama berhasil melakukan Login" (akun_id=$akunId)');
    } catch (e) {
      debugPrint('[AuditLogService] Gagal catat login: $e');
    }
  }

  String? _resolveSupabaseAuthEmail({
    required String normalizedIdentifier,
    required Map<String, dynamic> rawAccount,
    Map<String, dynamic>? pegawaiData,
  }) {
    if (normalizedIdentifier.contains('@')) {
      return normalizedIdentifier;
    }

    final pegawaiEmail = pegawaiData?['email']?.toString();
    if (pegawaiEmail != null && pegawaiEmail.isNotEmpty) {
      return pegawaiEmail;
    }

    final rawEmail = rawAccount['email']?.toString();
    if (rawEmail != null && rawEmail.isNotEmpty) {
      return rawEmail;
    }

    return null;
  }

  bool _verifyPassword(String inputPassword, String storedPassword) {
    if (storedPassword.startsWith(r'$2y$') ||
        storedPassword.startsWith(r'$2a$') ||
        storedPassword.startsWith(r'$2b$')) {
      try {
        return BCrypt.checkpw(inputPassword, storedPassword);
      } catch (_) {
        if (storedPassword.startsWith(r'$2y$')) {
          final normalizedHash = r'$2a$' + storedPassword.substring(4);
          try {
            return BCrypt.checkpw(inputPassword, normalizedHash);
          } catch (_) {
            return false;
          }
        }
        return false;
      }
    }

    return storedPassword == inputPassword;
  }
}


