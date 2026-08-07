class Pengajuan {
  final String id;
  final String jenis;
  final DateTime tanggal;
  final String status;
  final String pegawaiId;
  final String? lampiran;
  final String? keterangan;
  final DateTime? createdAt;

  const Pengajuan({
    required this.id,
    required this.jenis,
    required this.tanggal,
    required this.status,
    required this.pegawaiId,
    this.lampiran,
    this.keterangan,
    this.createdAt,
  });
}
