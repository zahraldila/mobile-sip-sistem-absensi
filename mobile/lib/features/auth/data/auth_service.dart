import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import '../domain/entities/auth_user.dart';
import '../services/auth_session_service.dart';

class AuthService {
  final Dio _dio;
  bool _loggedIn = false;

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
    final normalizedIdentifier = identifier.trim();
    final normalizedPassword = password.trim();

    if (normalizedIdentifier.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    try {
      final path = '/rest/v1/akun';
      final queryParameters = {
        'select': '*,pegawai!inner(*)',
        'pegawai.email': 'eq.$normalizedIdentifier',
        'password': 'eq.$normalizedPassword',
      };
      final requestUri = Uri.parse(
        _dio.options.baseUrl,
      ).resolve(path).replace(queryParameters: queryParameters);
      final options = await _buildRequestOptions();

      debugPrint('DIO BASE URL = ${_dio.options.baseUrl}');
      debugPrint('REQUEST PATH = $path');
      debugPrint('REQUEST URI = $requestUri');
      debugPrint('REQUEST QUERY = $queryParameters');
      debugPrint('REQUEST HEADERS = ${options.headers}');

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      debugPrint('STATUS = ${response.statusCode}');
      debugPrint('RESPONSE URI = ${response.realUri}');
      debugPrint('BODY = ${response.data}');

      if (response.statusCode == 200 &&
          response.data is List &&
          response.data.isNotEmpty) {
        final account = (response.data as List).first as Map<String, dynamic>;
        final pegawaiData = account['pegawai'];
        final Map<String, dynamic> pegawai = pegawaiData is List
            ? (pegawaiData.isNotEmpty
                  ? pegawaiData.first as Map<String, dynamic>
                  : <String, dynamic>{})
            : (pegawaiData as Map<String, dynamic>? ?? <String, dynamic>{});

        _loggedIn = true;

        final accessToken = _extractAccessToken(account, response);
        debugPrint('LOGIN accessToken present=${accessToken.isNotEmpty}');

        return AuthUser(
          akunId: account['akun_id']?.toString() ?? '',
          pegawaiId: account['pegawai_id']?.toString() ?? '',
          username: account['username']?.toString() ?? '',
          role: account['role']?.toString() ?? '',
          namaPegawai: pegawai['nama_pegawai']?.toString() ?? '',
          email: pegawai['email']?.toString() ?? '',
          jabatan: pegawai['jabatan']?.toString() ?? '',
          divisi: pegawai['divisi']?.toString() ?? '',
          fotoProfile: pegawai['foto_profile']?.toString() ?? '',
          accessToken: accessToken,
        );
      }
    } on DioException catch (e) {
      debugPrint('ERROR');
      debugPrint(e.response?.statusCode.toString());
      debugPrint(e.response?.data.toString());
      rethrow;
    }

    return null;
  }

  Future<bool> isLoggedIn() async {
    return _loggedIn;
  }

  Future<Map<String, dynamic>?> getPegawaiDetail(String pegawaiId) async {
    try {
      final path = '/rest/v1/pegawai';
      final queryParameters = {
        'pegawai_id': 'eq.$pegawaiId',
        'select': '*',
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
        return response.data.first as Map<String, dynamic>;
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

  String _extractAccessToken(Map<String, dynamic> account, Response response) {
    final candidates = <dynamic>[
      account['access_token'],
      account['token'],
      account['jwt'],
      if (response.data is Map<String, dynamic>)
        (response.data as Map<String, dynamic>)['access_token'],
      if (response.data is Map<String, dynamic>)
        (response.data as Map<String, dynamic>)['token'],
      if (response.data is Map<String, dynamic>)
        (response.data as Map<String, dynamic>)['jwt'],
      response.headers.value('authorization'),
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isEmpty) continue;
      if (value.toLowerCase().startsWith('bearer ')) {
        return value.substring(7).trim();
      }
      return value;
    }

    return '';
  }
}


