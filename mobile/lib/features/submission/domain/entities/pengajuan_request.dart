class PengajuanRequest {
  final String pegawaiId;
  final String jenisPengajuan;
  final List<DateTime> tanggalPengajuan;
  final String? lampiran;
  final String? keterangan;

  const PengajuanRequest({
    required this.pegawaiId,
    required this.jenisPengajuan,
    required this.tanggalPengajuan,
    this.lampiran,
    this.keterangan,
  });
}
