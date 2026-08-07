import 'dart:io';

import '../repositories/profile_repository.dart';

class UpdateProfilePhotoUseCase {
  UpdateProfilePhotoUseCase(this._repository);

  final ProfileRepository _repository;

  Future<String> execute({
    required String pegawaiId,
    required File imageFile,
  }) async {
    final uploadedUrl = await _repository.uploadProfilePhoto(
      pegawaiId: pegawaiId,
      imageFile: imageFile,
    );

    final updated = await _repository.updatePegawaiPhoto(
      pegawaiId: pegawaiId,
      photoUrl: uploadedUrl,
    );

    if (!updated) {
      throw Exception('Gagal memperbarui foto profil di database.');
    }

    return uploadedUrl;
  }
}
