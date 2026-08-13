import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: SupabaseConfig.url,
              headers: {
                'apikey': SupabaseConfig.anonKey,
                'Accept': 'application/json',
              },
            ),
          );

  final Dio _dio;
  static const List<String> _photoColumns = ['foto_profile', 'foto_profil'];
  static const List<String> _candidateBuckets = ['profile-images', 'foto_profile'];

  Future<Options> _buildRequestOptions({
    bool preferRepresentation = false,
    Map<String, dynamic>? extraHeaders,
  }) async {
    final headers = <String, dynamic>{
      'apikey': SupabaseConfig.anonKey,
      'Accept': 'application/json',
      ...?extraHeaders,
    };

    final token = AuthState.instance.currentUser?.accessToken;
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

  Future<Map<String, dynamic>?> fetchPegawaiDetail(String pegawaiId) async {
    final response = await _dio.get(
      '/rest/v1/pegawai',
      queryParameters: {
        'pegawai_id': 'eq.$pegawaiId',
        'select': '*,master_divisi(nama_divisi),master_jabatan(nama_jabatan)',
      },
      options: await _buildRequestOptions(),
    );

    if (response.statusCode == 200 &&
        response.data is List &&
        (response.data as List).isNotEmpty) {
      final rawDetail = (response.data as List).first as Map<String, dynamic>;

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

    return null;
  }

  Future<String> uploadProfilePhoto({
    required String pegawaiId,
    required File imageFile,
  }) async {
    final fileBytes = await imageFile.readAsBytes();
    final ext = path.extension(imageFile.path).toLowerCase();
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    final contentType = _contentTypeForExtension(safeExt);
    final objectPath = 'pegawai_${pegawaiId}_${DateTime.now().millisecondsSinceEpoch}$safeExt';

    DioException? lastError;

    for (final bucket in _candidateBuckets) {
      try {
        final fullPath = '/storage/v1/object/$bucket/$objectPath';
        debugPrint('====== MENCOBA UPLOAD KE BUCKET: $bucket ======');
        debugPrint('Path: $fullPath');
        
        final uploadResponse = await _dio.post(
          fullPath,
          data: fileBytes,
          options: await _buildRequestOptions(
            extraHeaders: {
              'Content-Type': contentType,
              'x-upsert': 'false',
            },
          ),
        );

        debugPrint('Response status for $bucket: ${uploadResponse.statusCode}');
        debugPrint('Response data for $bucket: ${uploadResponse.data}');

        if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
          debugPrint('====== UPLOAD BERHASIL KE BUCKET: $bucket ======');
          return '$bucket/$objectPath';
        } else {
          lastError = DioException(
            requestOptions: uploadResponse.requestOptions,
            response: uploadResponse,
            message: 'Status code: ${uploadResponse.statusCode}, body: ${uploadResponse.data}',
          );
        }
      } on DioException catch (e) {
        debugPrint('DioException for $bucket: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
        lastError = e;
      }
    }

    throw Exception(
      'Upload ke Supabase Storage gagal. ${lastError?.response?.data ?? lastError?.message ?? ''}',
    );
  }

  Future<bool> updatePegawaiPhoto({
    required String pegawaiId,
    required String photoUrl,
  }) async {
    for (final column in _photoColumns) {
      try {
        debugPrint('====== MENCOBA UPDATE DATABASE KOLOM: $column ======');
        final response = await _dio.patch(
          '/rest/v1/pegawai',
          queryParameters: {
            'pegawai_id': 'eq.$pegawaiId',
            'select': '*',
          },
          data: {column: photoUrl},
          options: await _buildRequestOptions(preferRepresentation: true),
        );

        debugPrint('Response update status for $column: ${response.statusCode}');
        debugPrint('Response update data for $column: ${response.data}');

        if ((response.statusCode == 200 || response.statusCode == 204) &&
            ((response.data is List && (response.data as List).isNotEmpty) ||
                response.statusCode == 204)) {
          debugPrint('====== UPDATE DATABASE BERHASIL KOLOM: $column ======');
          return true;
        }
      } on DioException catch (e) {
        debugPrint('DioException update kolom $column: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      } catch (e) {
        debugPrint('Error update kolom $column: $e');
      }
    }

    return false;
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
