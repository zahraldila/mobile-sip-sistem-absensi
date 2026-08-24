/// Helper untuk memformat pesan error teknis menjadi pesan yang ramah pengguna.
class ErrorHelpers {
  /// Mengubah exception teknis menjadi pesan bahasa Indonesia yang mudah dipahami.
  static String formatUserFriendlyMessage(
    dynamic error, {
    bool isCheckOut = false,
  }) {
    if (error == null) {
      return isCheckOut
          ? 'Check Out gagal. Silakan coba lagi.'
          : 'Check In gagal. Silakan coba lagi.';
    }

    final str = error.toString().toLowerCase();

    // 1. Deteksi Masalah Koneksi Internet / Jaringan Offline
    if (str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('connection error') ||
        str.contains('connection refused') ||
        str.contains('clientexception') ||
        str.contains('xmlhttprequest error') ||
        str.contains('handshakeexception') ||
        str.contains('connection closed') ||
        str.contains('timed out') ||
        str.contains('timeout') ||
        str.contains('no address associated with hostname') ||
        str.contains('network error') ||
        str.contains('dioexception') ||
        str.contains('offline')) {
      return isCheckOut
          ? 'Check Out gagal karena tidak ada koneksi internet. Silakan periksa koneksi Anda dan coba lagi.'
          : 'Check In gagal karena tidak ada koneksi internet. Silakan periksa koneksi Anda dan coba lagi.';
    }

    // 2. Deteksi Sesi Login Berakhir / Token Invalid
    if (str.contains('jwt') ||
        str.contains('session') ||
        str.contains('unauthorized') ||
        str.contains('authenticationexception') ||
        str.contains('token expired')) {
      return 'Sesi login telah berakhir. Silakan logout lalu login kembali.';
    }

    // 3. Deteksi NFC Card mismatch
    if (str.contains('nfc') && (str.contains('tidak terdaftar') || str.contains('tidak sesuai'))) {
      return 'Kartu NFC tidak terdaftar untuk akun Anda. Silakan gunakan kartu terdaftar.';
    }

    // 4. Deteksi GPS / Lokasi
    if (str.contains('location') || str.contains('gps') || str.contains('permission')) {
      return 'Gagal memverifikasi lokasi. Pastikan GPS aktif dan izin lokasi telah diberikan.';
    }

    // 5. Fallback ramah pengguna tanpa mengekspos class exception teknis
    return isCheckOut
        ? 'Check Out gagal diproses. Silakan periksa koneksi atau coba beberapa saat lagi.'
        : 'Check In gagal diproses. Silakan periksa koneksi atau coba beberapa saat lagi.';
  }
}
