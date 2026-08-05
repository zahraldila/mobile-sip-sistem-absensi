import '../entities/pengajuan.dart';

abstract class PengajuanRepository {
  Future<List<Pengajuan>> getPengajuanByPegawai(String pegawaiId);
}
