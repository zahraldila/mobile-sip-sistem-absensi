import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';

/// Model untuk merepresentasikan item aktivitas pengguna.
class ActivityItemData {
  const ActivityItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBgColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.timePillBgColor,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeText;
  final String statusLabel;
  final Color statusColor;
  final Color statusBgColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color timePillBgColor;
  final DateTime createdAt;

  factory ActivityItemData.checkIn({
    required String timeText,
    String subtitle = 'Anda berhasil melakukan check in',
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'checkin_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Check In Berhasil',
      subtitle: subtitle,
      timeText: timeText,
      statusLabel: 'Berhasil',
      statusColor: const Color(0xFF27AE60),
      statusBgColor: const Color(0xFFEBF8F2),
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF27AE60),
      iconBgColor: const Color(0xFFE6F8EE),
      timePillBgColor: const Color(0xFFE2F3EB),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory ActivityItemData.checkOut({
    required String timeText,
    String subtitle = 'Anda berhasil melakukan check out',
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'checkout_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Check Out Berhasil',
      subtitle: subtitle,
      timeText: timeText,
      statusLabel: 'Berhasil',
      statusColor: const Color(0xFFEB5757),
      statusBgColor: const Color(0xFFFDECEE),
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFFEB5757),
      iconBgColor: const Color(0xFFFCE8E8),
      timePillBgColor: const Color(0xFFF9E4E4),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory ActivityItemData.pengajuan({
    required String title,
    required String subtitle,
    required String timeText,
    String status = 'Pending',
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'pengajuan_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      timeText: timeText,
      statusLabel: status,
      statusColor: const Color(0xFFB58E29),
      statusBgColor: const Color(0xFFFBF7EC),
      icon: Icons.assignment_outlined,
      iconColor: const Color(0xFFB58E29),
      iconBgColor: const Color(0xFFFDF6E2),
      timePillBgColor: const Color(0xFFF5EFE0),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory ActivityItemData.info({
    required String title,
    required String subtitle,
    required String timeText,
    String status = 'Info',
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'info_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      timeText: timeText,
      statusLabel: status,
      statusColor: AppColors.primary,
      statusBgColor: AppColors.primary.withValues(alpha: 0.08),
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.primary,
      iconBgColor: AppColors.primary.withValues(alpha: 0.12),
      timePillBgColor: AppColors.primary.withValues(alpha: 0.1),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory ActivityItemData.login({
    required String subtitle,
    required String timeText,
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'login_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Login',
      subtitle: subtitle,
      timeText: timeText,
      statusLabel: 'Berhasil',
      statusColor: const Color(0xFF27AE60),
      statusBgColor: const Color(0xFFE6F8EE),
      icon: Icons.login_rounded,
      iconColor: const Color(0xFF27AE60),
      iconBgColor: const Color(0xFFE6F8EE),
      timePillBgColor: const Color(0xFFF1F5F9),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory ActivityItemData.logout({
    required String subtitle,
    required String timeText,
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'logout_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Logout',
      subtitle: subtitle,
      timeText: timeText,
      statusLabel: 'Berhasil',
      statusColor: const Color(0xFFF2994A),
      statusBgColor: const Color(0xFFFDF4E6),
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFFF2994A),
      iconBgColor: const Color(0xFFFDF4E6),
      timePillBgColor: const Color(0xFFF1F5F9),
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

/// Singleton Service pengelola aktivitas real-time
class ActivityService extends ChangeNotifier {
  ActivityService._();

  static final ActivityService instance = ActivityService._();

  final List<ActivityItemData> _activities = [];
  String? _loadedAkunId;

  List<ActivityItemData> get activities => List.unmodifiable(_activities);

  void clear() {
    _activities.clear();
    _loadedAkunId = null;
    notifyListeners();
  }

  /// Memuat aktivitas absensi dan pengajuan nyata dari database
  Future<void> loadActivitiesFromDatabase() async {
      final currentUser = AuthState.instance.currentUser;
      final pegawaiId = currentUser?.pegawaiId ?? '';
      final akunId = currentUser?.akunId ?? '';

      // Muat log lokal (termasuk logout sebelumnya) jika akunId berubah, atau belum pernah dimuat
      if (_loadedAkunId != akunId) {
        final restored = await _loadSavedLocalActivities(akunId);
        // Gabungkan dengan yang sudah ada di _activities (misal log login yang baru saja ditambah)
        for (final r in restored) {
          if (!_activities.any((a) => a.id == r.id)) {
            _activities.add(r);
          }
        }
        _loadedAkunId = akunId;
      }

    try {
      final token = AuthState.instance.currentUser?.accessToken;
      final headers = {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${token != null && token.isNotEmpty ? token : SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final dio = Dio(BaseOptions(baseUrl: SupabaseConfig.url, headers: headers));
      final List<ActivityItemData> newActivities = [];

      // 1. Ambil data absensi nyata (Check In & Check Out) dari tabel absensi
      if (pegawaiId.isNotEmpty) {
        try {
          final absensiRes = await dio.get(
            '/rest/v1/absensi',
            queryParameters: {
              'pegawai_id': 'eq.$pegawaiId',
              'select': 'absensi_id,tanggal_absensi,jam_checkin,jam_checkout,skema_kerja,catatan',
              'order': 'tanggal_absensi.desc,absensi_id.desc',
              'limit': '20',
            },
          );

          if (absensiRes.statusCode == 200 && absensiRes.data is List) {
            final list = absensiRes.data as List;
            for (final item in list) {
              final map = item as Map<String, dynamic>;
              final absensiId = map['absensi_id']?.toString() ?? '';
              final skema = map['skema_kerja']?.toString() ?? 'WFO';
              final catatan = map['catatan']?.toString() ?? '';

              // Check In
              final checkInStr = map['jam_checkin']?.toString();
              if (checkInStr != null && checkInStr.isNotEmpty && checkInStr != 'null') {
                final dt = DateTime.tryParse(checkInStr)?.toLocal();
                if (dt != null) {
                  final timeText = _formatActivityTime(dt);
                  final isCheckoutNote = catatan.toLowerCase().contains('check-out') || catatan.toLowerCase().contains('checkout');
                  final subtitle = (catatan.isNotEmpty && !isCheckoutNote)
                      ? _cleanCatatan(catatan)
                      : 'Anda berhasil melakukan check in ($skema)';
                  newActivities.add(
                    ActivityItemData.checkIn(
                      id: 'checkin_$absensiId',
                      subtitle: subtitle,
                      timeText: timeText,
                      createdAt: dt,
                    ),
                  );
                }
              }

              // Check Out
              final checkOutStr = map['jam_checkout']?.toString();
              if (checkOutStr != null && checkOutStr.isNotEmpty && checkOutStr != 'null') {
                final dt = DateTime.tryParse(checkOutStr)?.toLocal();
                if (dt != null) {
                  final timeText = _formatActivityTime(dt);
                  final isCheckoutNote = catatan.toLowerCase().contains('check-out') || catatan.toLowerCase().contains('checkout');
                  final subtitle = (catatan.isNotEmpty && isCheckoutNote)
                      ? _cleanCatatan(catatan)
                      : 'Anda berhasil melakukan check out ($skema)';
                  newActivities.add(
                    ActivityItemData.checkOut(
                      id: 'checkout_$absensiId',
                      subtitle: subtitle,
                      timeText: timeText,
                      createdAt: dt,
                    ),
                  );
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[ActivityService] Error fetching absensi table: $e');
        }
      }

      // 2. Ambil data aktivitas audit tambahan (Profil, Pengajuan, dll) dari audit_log
      if (akunId.isNotEmpty) {
        try {
          final resolvedAkunId = int.tryParse(akunId) ?? akunId;
          final auditRes = await dio.get(
            '/rest/v1/audit_log',
            queryParameters: {
              'akun_id': 'eq.$resolvedAkunId',
              'select': 'log_id,aktivitas,waktu_log',
              'order': 'waktu_log.desc',
              'limit': '20',
            },
          );

          if (auditRes.statusCode == 200 && auditRes.data is List) {
            debugPrint('[ActivityService] audit_log data: ${auditRes.data}');
            final list = auditRes.data as List;
            for (final item in list) {
              final map = item as Map<String, dynamic>;
              final aktivitas = map['aktivitas']?.toString().trim() ?? '';
              final waktuLog = DateTime.tryParse(map['waktu_log']?.toString() ?? '')?.toLocal();

              if (aktivitas.isEmpty || waktuLog == null) {
                continue;
              }

              final norm = aktivitas.toLowerCase();
              // Lewati log Check In / Check Out dari audit_log karena sudah diambil secara presisi dari tabel absensi
              if (norm.contains('check in') || norm.contains('check out')) {
                continue;
              }

              newActivities.add(
                _activityFromAuditLog(
                  id: map['log_id']?.toString() ?? 'audit_${waktuLog.millisecondsSinceEpoch}',
                  aktivitas: aktivitas,
                  createdAt: waktuLog,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('[ActivityService] Error fetching audit_log table: $e');
        }
      }

      // Restorasi aktivitas lokal sesi hari ini dari SharedPreferences
      final savedLocals = await _loadSavedLocalActivities(akunId);
      for (final saved in savedLocals) {
        if (!newActivities.any((a) => a.id == saved.id || (a.title == saved.title && a.createdAt.difference(saved.createdAt).abs().inMinutes < 5))) {
          newActivities.add(saved);
        }
      }

      // Sertakan juga aktivitas lokal yang sedang aktif di memori
      final now = DateTime.now();
      for (final existing in _activities) {
        if (existing.id.startsWith('local_') &&
            existing.createdAt.year == now.year &&
            existing.createdAt.month == now.month &&
            existing.createdAt.day == now.day) {
          if (!newActivities.any((a) => a.id == existing.id || (a.title == existing.title && a.createdAt.difference(existing.createdAt).abs().inMinutes < 5))) {
            newActivities.add(existing);
          }
        }
      }

      // Filter HANYA aktivitas HARI INI
      final todayActivities = newActivities.where((item) {
        return item.createdAt.year == now.year &&
            item.createdAt.month == now.month &&
            item.createdAt.day == now.day;
      }).toList();

      // Urutkan seluruh aktivitas gabungan hari ini berdasarkan waktu terbaru
      todayActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _activities.clear();
      _activities.addAll(todayActivities);
      _loadedAkunId = akunId;
      await _saveLocalActivities(akunId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ActivityService] Error loading activities from DB: $e');
    }
  }

  Future<void> recordAuditActivity(
    String aktivitas, {
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final item = _activityFromAuditLog(
      id: 'local_${now.millisecondsSinceEpoch}',
      aktivitas: aktivitas,
      createdAt: now,
    );
    _activities.insert(0, item);
    if (_loadedAkunId != null) {
      await _saveLocalActivities(_loadedAkunId!);
    }
    notifyListeners();
  }

  static const _localActivitiesKey = 'today_local_activities';

  Future<void> _saveLocalActivities(String akunId) async {
    try {
      if (akunId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayItems = _activities.where((item) {
        return item.createdAt.year == now.year &&
            item.createdAt.month == now.month &&
            item.createdAt.day == now.day &&
            item.id.startsWith('local_');
      }).map((item) => {
        'id': item.id,
        'title': item.title,
        'subtitle': item.subtitle,
        'timeText': item.timeText,
        'statusLabel': item.statusLabel,
        'createdAt': item.createdAt.toIso8601String(),
      }).toList();

      await prefs.setString('${_localActivitiesKey}_$akunId', jsonEncode(todayItems));
    } catch (e) {
      debugPrint('[ActivityService] Error saving local activities: $e');
    }
  }

  Future<List<ActivityItemData>> _loadSavedLocalActivities(String akunId) async {
    try {
      if (akunId.isEmpty) return [];
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_localActivitiesKey}_$akunId');
      if (raw == null || raw.isEmpty) return [];

      final List list = jsonDecode(raw);
      final now = DateTime.now();
      final List<ActivityItemData> restored = [];

      for (final map in list) {
        final dt = DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toLocal();
        if (dt != null && dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          restored.add(
            ActivityItemData.info(
              id: map['id']?.toString() ?? 'local_${dt.millisecondsSinceEpoch}',
              title: map['title']?.toString() ?? 'Profil Diperbarui',
              subtitle: map['subtitle']?.toString() ?? 'Informasi kontak berhasil diperbarui',
              timeText: map['timeText']?.toString() ?? _formatActivityTime(dt),
              status: map['statusLabel']?.toString() ?? 'Diperbarui',
              createdAt: dt,
            ),
          );
        }
      }
      return restored;
    } catch (e) {
      debugPrint('[ActivityService] Error restoring local activities: $e');
      return [];
    }
  }

  ActivityItemData _activityFromAuditLog({
    required String id,
    required String aktivitas,
    required DateTime createdAt,
  }) {
    final normalized = aktivitas.toLowerCase();
    final timeText = _formatActivityTime(createdAt);

    if (normalized.contains('login')) {
      return ActivityItemData.login(
        id: id,
        subtitle: 'Log aktivitas akun Anda',
        timeText: timeText,
        createdAt: createdAt,
      );
    }

    if (normalized.contains('logout')) {
      return ActivityItemData.logout(
        id: id,
        subtitle: 'Log aktivitas akun Anda',
        timeText: timeText,
        createdAt: createdAt,
      );
    }

    if (normalized.contains('check out')) {
      return ActivityItemData.checkOut(
        id: id,
        subtitle: aktivitas,
        timeText: timeText,
        createdAt: createdAt,
      );
    }

    if (normalized.contains('check in')) {
      return ActivityItemData.checkIn(
        id: id,
        subtitle: aktivitas,
        timeText: timeText,
        createdAt: createdAt,
      );
    }

    if (normalized.contains('foto profil')) {
      return ActivityItemData.info(
        id: id,
        title: 'Foto Profil Diperbarui',
        subtitle: aktivitas,
        timeText: timeText,
        status: 'Diperbarui',
        createdAt: createdAt,
      );
    }

    if (normalized.contains('update data profil') ||
        normalized.contains('profil') ||
        normalized.contains('kontak') ||
        normalized.contains('memperbarui informasi kontak')) {
      return ActivityItemData.info(
        id: id,
        title: 'Profil Diperbarui',
        subtitle: 'Informasi kontak berhasil diperbarui',
        timeText: timeText,
        status: 'Diperbarui',
        createdAt: createdAt,
      );
    }

    if (normalized.contains('pengajuan')) {
      return ActivityItemData.info(
        id: id,
        title: aktivitas,
        subtitle: 'Log aktivitas akun Anda',
        timeText: timeText,
        status: 'Tercatat',
        createdAt: createdAt,
      );
    }

    return ActivityItemData.info(
      id: id,
      title: aktivitas,
      subtitle: 'Log aktivitas akun Anda',
      timeText: timeText,
      status: 'Info',
      createdAt: createdAt,
    );
  }

  String _formatActivityTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dtDay = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat('HH:mm').format(dt);

    if (dtDay == today) {
      return 'Hari Ini, $timeStr WIB';
    } else if (dtDay == yesterday) {
      return 'Kemarin, $timeStr WIB';
    } else {
      return '${DateFormat('dd MMM').format(dt)}, $timeStr WIB';
    }
  }

  /// Tambah aktivitas Check In secara real-time
  void recordCheckIn({DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    final timeFormatted = DateFormat('HH:mm').format(now);
    final item = ActivityItemData.checkIn(
      timeText: 'Hari Ini, $timeFormatted WIB',
      createdAt: now,
    );
    _activities.insert(0, item);
    notifyListeners();
  }

  /// Tambah aktivitas Check Out secara real-time
  void recordCheckOut({DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    final timeFormatted = DateFormat('HH:mm').format(now);
    final item = ActivityItemData.checkOut(
      timeText: 'Hari Ini, $timeFormatted WIB',
      createdAt: now,
    );
    _activities.insert(0, item);
    notifyListeners();
  }

  /// Tambah aktivitas Pengajuan secara real-time
  void recordPengajuan({
    required String title,
    required String subtitle,
    String status = 'Pending',
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final timeFormatted = DateFormat('HH:mm').format(now);
    final item = ActivityItemData.pengajuan(
      title: title,
      subtitle: subtitle,
      timeText: 'Hari Ini, $timeFormatted WIB',
      status: status,
      createdAt: now,
    );
    _activities.insert(0, item);
    notifyListeners();
  }

  /// Membersihkan tag teknis internal seperti [UID NFC: xx:xx:xx:xx] agar subtitle bersih untuk pengguna
  String _cleanCatatan(String raw) {
    return raw.replaceAll(RegExp(r'\s*\[UID NFC:[^\]]+\]', caseSensitive: false), '').trim();
  }
}
