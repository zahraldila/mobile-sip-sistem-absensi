import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import '../../domain/entities/pengajuan_request.dart';
import '../models/pengajuan_model.dart';

class PengajuanRemoteDataSource {
  final Dio _dio;

  PengajuanRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: SupabaseConfig.url, headers: {
        'apikey': SupabaseConfig.anonKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }));

  Future<Options> _buildRequestOptions({
    bool preferRepresentation = false,
    bool requireSession = false,
    Map<String, dynamic>? extraHeaders,
  }) async {
    final token = AuthState.instance.currentUser?.accessToken;
    if (requireSession && (token == null || token.isEmpty)) {
      throw Exception('Session login tidak ditemukan. Silakan login ulang.');
    }

    final headers = <String, dynamic>{
      'apikey': SupabaseConfig.anonKey,
      'Accept': 'application/json',
      ...?extraHeaders,
    };

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

  Future<String> uploadLampiran({
    required String pegawaiId,
    required File file,
  }) async {
    final fileBytes = await file.readAsBytes();
    final ext = path.extension(file.path).toLowerCase();
    final safeExt = ext.isNotEmpty ? ext : '.pdf';
    final baseName = path.basename(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = 'pengajuan/$pegawaiId/${timestamp}_$baseName';

    late DioException lastError;

    try {
      final fullPath = '/storage/v1/object/submission-files/$objectPath';

      final uploadResponse = await _dio.post(
        fullPath,
        data: fileBytes,
        options: await _buildRequestOptions(
          requireSession: false,
          extraHeaders: {
            'Content-Type': _contentTypeForExtension(safeExt),
            'x-upsert': 'false',
          },
        ),
      );

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
        return 'submission-files/$objectPath';
      } else {
        lastError = DioException(
          requestOptions: uploadResponse.requestOptions,
          response: uploadResponse,
          message: 'Status code: ${uploadResponse.statusCode}, body: ${uploadResponse.data}',
        );
      }
    } on DioException catch (e) {
      lastError = e;
    }

    final responseData = lastError.response?.data;
    final errorDetail = responseData != null ? responseData.toString() : lastError.message;
    throw Exception('Upload ke Supabase Storage gagal. ${errorDetail ?? ''}');
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.pdf':
      default:
        return 'application/pdf';
    }
  }
}
