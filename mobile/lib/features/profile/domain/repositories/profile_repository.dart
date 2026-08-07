import 'dart:io';

abstract class ProfileRepository {
  Future<Map<String, dynamic>?> fetchPegawaiDetail(String pegawaiId);

  Future<String> uploadProfilePhoto({
    required String pegawaiId,
    required File imageFile,
  });

  Future<bool> updatePegawaiPhoto({
    required String pegawaiId,
    required String photoUrl,
  });
}
