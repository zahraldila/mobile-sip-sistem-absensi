import '../../domain/entities/pengajuan.dart';

class PengajuanModel extends Pengajuan {
  const PengajuanModel({required super.id, required super.jenis, required super.tanggal, required super.status, required super.pegawaiId});

  factory PengajuanModel.fromMap(Map<String, dynamic> map) {
    // fields may vary; try common names
    final id = (map['pengajuan_id'] ?? map['id'] ?? map['id_pengajuan'])?.toString() ?? '';
    final jenis = (map['jenis_pengajuan'] ?? map['jenis'] ?? map['type'])?.toString() ?? '';
    final tanggalStr = map['tanggal_pengajuan'] ?? map['tanggal'] ?? map['created_at'];
    DateTime tanggal;
    if (tanggalStr is String) {
      tanggal = DateTime.tryParse(tanggalStr) ?? DateTime.now();
    } else if (tanggalStr is DateTime) {
      tanggal = tanggalStr;
    } else {
      tanggal = DateTime.now();
    }
    final status = (map['status_pengajuan'] ?? map['status'] ?? '')?.toString() ?? '';
    final pegawaiId = (map['pegawai_id'] ?? map['pegawaiId'] ?? map['pegawai_id_fk'])?.toString() ?? '';

    return PengajuanModel(id: id, jenis: jenis, tanggal: tanggal, status: status, pegawaiId: pegawaiId);
  }
}
