import '../../domain/entities/pengajuan.dart';
import '../../domain/entities/pengajuan_request.dart';
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

  @override
  Future<void> createPengajuan(PengajuanRequest request) async {
    await remote.createPengajuan(request);
  }
}
