import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan dan membaca status "sudah dibaca" notifikasi
/// menggunakan [SharedPreferences] (konsisten dengan [AuthSessionService]).
///
/// Key format: `notification_read_{notifikasiId}`
class NotificationReadService {
  static const String _prefix = 'notification_read_';

  /// Mengembalikan `true` jika notifikasi dengan [notifikasiId] sudah dibaca.
  Future<bool> isRead(String notifikasiId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$notifikasiId') ?? false;
  }

  /// Menandai notifikasi dengan [notifikasiId] sebagai sudah dibaca.
  Future<void> markAsRead(String notifikasiId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$notifikasiId', true);
  }

  /// Membaca status baca untuk sekumpulan [notifikasiIds] sekaligus.
  /// Mengembalikan `Map` dengan key `notifikasiId` dan value `bool` (isRead).
  Future<Map<String, bool>> fetchReadStatuses(List<String> notifikasiIds) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, bool> result = {};
    for (final id in notifikasiIds) {
      result[id] = prefs.getBool('$_prefix$id') ?? false;
    }
    return result;
  }
}
