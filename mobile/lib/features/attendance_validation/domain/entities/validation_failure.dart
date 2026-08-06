import 'package:equatable/equatable.dart';

abstract class ValidationFailure extends Equatable {
  final String message;
  final String? actionHint;

  const ValidationFailure({
    required this.message,
    this.actionHint,
  });

  @override
  List<Object?> get props => [message, actionHint];
}

class PermissionDeniedFailure extends ValidationFailure {
  final bool isPermanentlyDenied;

  const PermissionDeniedFailure({
    required super.message,
    this.isPermanentlyDenied = false,
    super.actionHint,
  });

  @override
  List<Object?> get props => [message, isPermanentlyDenied, actionHint];
}

class GpsDisabledFailure extends ValidationFailure {
  const GpsDisabledFailure({
    super.message = 'GPS atau Layanan Lokasi perangkat Anda sedang tidak aktif.',
    super.actionHint = 'Silakan aktifkan GPS/Layanan Lokasi di perangkat Anda lalu coba lagi.',
  });
}

class LocationFetchTimeoutFailure extends ValidationFailure {
  const LocationFetchTimeoutFailure({
    super.message = 'Waktu pengambilan koordinat lokasi GPS habis (timeout).',
    super.actionHint = 'Pastikan Anda berada di area terbuka dan koneksi GPS stabil.',
  });
}

class LocationFetchErrorFailure extends ValidationFailure {
  final String details;

  const LocationFetchErrorFailure({
    required this.details,
    super.message = 'Gagal memperoleh koordinat lokasi perangkat.',
    super.actionHint = 'Coba restart GPS atau buka kembali aplikasi.',
  });

  @override
  List<Object?> get props => [message, details, actionHint];
}

class OutOfRadiusFailure extends ValidationFailure {
  final double currentDistance;
  final double maxAllowedRadius;

  const OutOfRadiusFailure({
    required this.currentDistance,
    required this.maxAllowedRadius,
    super.message = 'Lokasi Anda berada di luar radius kantor yang diizinkan.',
    super.actionHint = 'Pastikan Anda sudah berada di lokasi kantor sesuai aturan absensi.',
  });

  @override
  List<Object?> get props => [message, currentDistance, maxAllowedRadius, actionHint];
}

class WifiNotConnectedFailure extends ValidationFailure {
  const WifiNotConnectedFailure({
    super.message = 'Perangkat tidak terhubung ke jaringan Wi-Fi.',
    super.actionHint = 'Silakan aktifkan Wi-Fi dan hubungkan ke salah satu jaringan Wi-Fi kantor.',
  });
}

class WifiNotAllowedFailure extends ValidationFailure {
  final String currentSsid;
  final List<String> allowedSsids;

  const WifiNotAllowedFailure({
    required this.currentSsid,
    required this.allowedSsids,
    super.message = 'Wi-Fi yang terhubung bukan merupakan jaringan resmi kantor.',
    super.actionHint = 'Silakan ganti koneksi ke salah satu Wi-Fi kantor yang terdaftar.',
  });

  @override
  List<Object?> get props => [message, currentSsid, allowedSsids, actionHint];
}

class NetworkFailure extends ValidationFailure {
  const NetworkFailure({
    super.message = 'Koneksi internet tidak tersedia atau bermasalah.',
    super.actionHint = 'Periksa koneksi data seluler atau Wi-Fi Anda.',
  });
}

class UnknownValidationFailure extends ValidationFailure {
  final String error;

  const UnknownValidationFailure({
    required this.error,
    super.message = 'Terjadi kesalahan tidak terduga saat melakukan validasi.',
    super.actionHint = 'Silakan coba beberapa saat lagi.',
  });

  @override
  List<Object?> get props => [message, error, actionHint];
}
