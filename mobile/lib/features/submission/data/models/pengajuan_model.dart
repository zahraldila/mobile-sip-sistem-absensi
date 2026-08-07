import '../../domain/entities/pengajuan.dart';

class PengajuanModel extends Pengajuan {
  const PengajuanModel({
    required super.id,
    required super.jenis,
    required super.tanggal,
    required super.status,
    required super.pegawaiId,
    super.lampiran,
    super.keterangan,
    super.createdAt,
  });

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
    final lampiran = (map['lampiran'] ?? map['file_name'] ?? map['filename'])?.toString();
    final keterangan = (map['keterangan'] ?? map['catatan'] ?? map['notes'])?.toString();
    final createdAtValue = map['created_at'] ?? map['createdAt'] ?? map['submitted_at'];
    DateTime? createdAt;
    if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue);
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    }

    return PengajuanModel(
      id: id,
      jenis: jenis,
      tanggal: tanggal,
      status: status,
      pegawaiId: pegawaiId,
      lampiran: lampiran,
      keterangan: keterangan,
      createdAt: createdAt,
    );
  }
}
