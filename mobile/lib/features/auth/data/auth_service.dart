import 'package:dio/dio.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import '../domain/entities/auth_user.dart';

class AuthService {
  final Dio _dio;
  bool _loggedIn = false;

  AuthService({Dio? dio})
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

  Future<AuthUser?> login({required String identifier, required String password}) async {
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
      final requestUri = Uri.parse(_dio.options.baseUrl).resolve(path).replace(queryParameters: queryParameters);

      print('DIO BASE URL = ${_dio.options.baseUrl}');
      print('REQUEST PATH = $path');
      print('REQUEST URI = $requestUri');
      print('REQUEST QUERY = $queryParameters');
      print('REQUEST HEADERS = ${_dio.options.headers}');

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      print('STATUS = ${response.statusCode}');
      print('RESPONSE URI = ${response.realUri}');
      print('BODY = ${response.data}');

      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
        final account = (response.data as List).first as Map<String, dynamic>;
        final pegawaiData = account['pegawai'];
        final Map<String, dynamic> pegawai = pegawaiData is List
            ? (pegawaiData.isNotEmpty ? pegawaiData.first as Map<String, dynamic> : <String, dynamic>{})
            : (pegawaiData as Map<String, dynamic>? ?? <String, dynamic>{});

        _loggedIn = true;

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
        );
      }
    } on DioException catch (e) {
      print("ERROR");
      print(e.response?.statusCode);
      print(e.response?.data);
      rethrow;
    }

    return null;
  }

  Future<bool> isLoggedIn() async {
    return _loggedIn;
  }
}
