import '../entities/pengajuan_request.dart';
import '../repositories/pengajuan_repository.dart';

class CreatePengajuan {
  final PengajuanRepository repository;

  CreatePengajuan(this.repository);

  Future<void> call(PengajuanRequest request) async {
    await repository.createPengajuan(request);
  }
}
