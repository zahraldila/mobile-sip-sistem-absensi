import '../entities/pengajuan.dart';
import '../repositories/pengajuan_repository.dart';

class GetPengajuans {
  final PengajuanRepository repository;

  GetPengajuans(this.repository);

  Future<List<Pengajuan>> call(String pegawaiId) async {
    return repository.getPengajuanByPegawai(pegawaiId);
  }
}
