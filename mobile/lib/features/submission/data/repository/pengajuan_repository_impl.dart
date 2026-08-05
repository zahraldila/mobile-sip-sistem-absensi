import '../../domain/entities/pengajuan.dart';
import '../datasource/pengajuan_remote_data_source.dart';
import '../../domain/repositories/pengajuan_repository.dart';

class PengajuanRepositoryImpl implements PengajuanRepository {
  final PengajuanRemoteDataSource remote;

  PengajuanRepositoryImpl({required this.remote});

  @override
  Future<List<Pengajuan>> getPengajuanByPegawai(String pegawaiId) async {
    final models = await remote.fetchPengajuanByPegawai(pegawaiId);
    return models;
  }
}
