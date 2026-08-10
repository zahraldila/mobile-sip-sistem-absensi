/// Model yang merepresentasikan baris dari tabel [notifikasi] di Supabase.
class NotificationModel {
  const NotificationModel({
    required this.notifikasiId,
    required this.pegawaiId,
    required this.judul,
    required this.isiPesan,
    required this.tanggalKirim,
  });

  final String notifikasiId;
  final String pegawaiId;
  final String judul;
  final String isiPesan;
  final DateTime tanggalKirim;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notifikasiId: json['notifikasi_id']?.toString() ?? '',
      pegawaiId: json['pegawai_id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      isiPesan: json['isi_pesan']?.toString() ?? '',
      tanggalKirim: json['tanggal_kirim'] != null
          ? (() {
              String dateStr = json['tanggal_kirim'].toString().trim();
              final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(dateStr);
              if (!hasTimezone) {
                dateStr = '${dateStr.replaceAll(' ', 'T')}Z';
              }
              return DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
            })()
          : DateTime.now(),
    );
  }
}
