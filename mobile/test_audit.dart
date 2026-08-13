import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://fxovkmcrdeezrotwqjhb.supabase.co',
      headers: {
        'apikey': 'sb_publishable_kAQnCpDKE2Fzo2SQ8kze0A_fHA0hd8q',
        'Authorization': 'Bearer sb_publishable_kAQnCpDKE2Fzo2SQ8kze0A_fHA0hd8q',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Prefer': 'return=representation',
      },
    ),
  );

  try {
    final response = await dio.post(
      '/rest/v1/audit_log',
      data: {
        'akun_id': 1,
        'aktivitas': 'Test Logging',
        'waktu_log': DateTime.now().toIso8601String(),
      },
    );
    print('Success: ${response.statusCode} - ${response.data}');
  } on DioException catch (e) {
    print('Error ${e.response?.statusCode}: ${e.response?.data}');
  } catch (e) {
    print('Unknown error: $e');
  }
}
