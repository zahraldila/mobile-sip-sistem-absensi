import 'package:bcrypt/bcrypt.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
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

    final token = await AuthSessionService().restoreToken();
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

      _loggedIn = true;
      return AuthUser(
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
        accessToken: '',
      );
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

      if (response.data is List) {
        return (response.data as List).isNotEmpty;
      }

      return response.statusCode == 204 || response.data != null;
    } catch (e) {
      debugPrint('ERROR UPDATE');
      debugPrint(e.toString());
      return false;
    }
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


