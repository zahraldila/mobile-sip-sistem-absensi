import 'dart:io';

import 'package:sip_sistem_absensi_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, dynamic>?> fetchPegawaiDetail(String pegawaiId) {
    return _remoteDataSource.fetchPegawaiDetail(pegawaiId);
  }

  @override
  Future<String> uploadProfilePhoto({
    required String pegawaiId,
    required File imageFile,
  }) {
    return _remoteDataSource.uploadProfilePhoto(
      pegawaiId: pegawaiId,
      imageFile: imageFile,
    );
  }

  @override
  Future<bool> updatePegawaiPhoto({
    required String pegawaiId,
    required String photoUrl,
  }) {
    return _remoteDataSource.updatePegawaiPhoto(
      pegawaiId: pegawaiId,
      photoUrl: photoUrl,
    );
  }
}
