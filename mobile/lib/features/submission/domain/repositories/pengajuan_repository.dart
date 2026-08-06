import '../entities/pengajuan.dart';
import '../entities/pengajuan_request.dart';

abstract class PengajuanRepository {
  Future<List<Pengajuan>> getPengajuanByPegawai(String pegawaiId);
  Future<void> createPengajuan(PengajuanRequest request);
}
