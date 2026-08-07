import 'dart:io';

import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/domain/usecases/update_profile_photo_usecase.dart';

class ProfilePhotoService {
  ProfilePhotoService({UpdateProfilePhotoUseCase? updateUseCase})
    : _updateUseCase =
          updateUseCase ??
          UpdateProfilePhotoUseCase(
            ProfileRepositoryImpl(ProfileRemoteDataSource()),
          );

  final UpdateProfilePhotoUseCase _updateUseCase;

  Future<Map<String, dynamic>?> fetchLatestProfile(String pegawaiId) async {
    final repository = ProfileRepositoryImpl(ProfileRemoteDataSource());
    return repository.fetchPegawaiDetail(pegawaiId);
  }

  Future<String> updateProfilePhoto({
    required String pegawaiId,
    required File imageFile,
  }) async {
    final uploadedUrl = await _updateUseCase.execute(
      pegawaiId: pegawaiId,
      imageFile: imageFile,
    );

    await AuthState.instance.updateCurrentUserFotoProfile(uploadedUrl);
    return uploadedUrl;
  }

  String? resolvePhotoUrl(Map<String, dynamic>? pegawaiData) {
    final raw =
        pegawaiData?['foto_profil']?.toString() ??
        pegawaiData?['foto_profile']?.toString() ??
        '';

    if (raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    return raw;
  }
}
