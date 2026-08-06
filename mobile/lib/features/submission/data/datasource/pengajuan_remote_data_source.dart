import 'package:dio/dio.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import '../../domain/entities/pengajuan_request.dart';
import '../models/pengajuan_model.dart';

class PengajuanRemoteDataSource {
  final Dio _dio;

  PengajuanRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: SupabaseConfig.url, headers: {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }));

  Future<List<PengajuanModel>> fetchPengajuanByPegawai(String pegawaiId) async {
    final path = '/rest/v1/pengajuan';
    final queryParameters = {
      'select': '*',
      'pegawai_id': 'eq.$pegawaiId',
      'order': 'tanggal_pengajuan.desc',
    };

    final resp = await _dio.get(path, queryParameters: queryParameters);
    if (resp.statusCode == 200 && resp.data is List) {
      final list = resp.data as List;
      return list.map((e) => PengajuanModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load pengajuan');
  }

  Future<void> createPengajuan(PengajuanRequest request) async {
    final path = '/rest/v1/pengajuan';
    final records = request.tanggalPengajuan.map((date) {
      final record = {
        'pegawai_id': request.pegawaiId,
        'jenis_pengajuan': request.jenisPengajuan,
        'tanggal_pengajuan': date.toIso8601String().split('T').first,
        'status_pengajuan': 'Pending',
      };

      if (request.lampiran != null && request.lampiran!.trim().isNotEmpty) {
        record['lampiran'] = request.lampiran!.trim();
      }

      if (request.keterangan != null && request.keterangan!.trim().isNotEmpty) {
        record['keterangan'] = request.keterangan!.trim();
      }

      return record;
    }).toList();

    print(records);

    final resp = await _dio.post(path,
        data: records,
        options: Options(headers: {
          'Prefer': 'return=minimal',
        }));

    if (resp.statusCode == 201 || resp.statusCode == 204) {
      return;
    }

    throw Exception('Failed to create pengajuan: ${resp.statusCode} ${resp.data}');
  }
}
