import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';
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
      statusColor: const Color(0xFF2F80ED),
      statusBgColor: const Color(0xFFEBF4FE),
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFF2F80ED),
      iconBgColor: const Color(0xFFE0F0FC),
      timePillBgColor: const Color(0xFFE2F0FA),
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

  /// Memuat aktivitas absensi dan pengajuan nyata dari database
  Future<void> loadActivitiesFromDatabase() async {
    final currentUser = AuthState.instance.currentUser;
    final akunId = currentUser?.akunId ?? '';
    if (akunId.isEmpty) {
      _loadedAkunId = null;
      _activities.clear();
      notifyListeners();
      return;
    }

    if (_loadedAkunId != akunId) {
      _activities.clear();
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

      final response = await dio.get(
        '/rest/v1/audit_log',
        queryParameters: {
          'akun_id': 'eq.$akunId',
          'select': 'log_id,aktivitas,waktu_log',
          'order': 'waktu_log.desc',
        },
      );

      final List<ActivityItemData> newActivities = [];

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final aktivitas = map['aktivitas']?.toString().trim() ?? '';
          final waktuLog = DateTime.tryParse(map['waktu_log']?.toString() ?? '')?.toLocal();

          if (aktivitas.isEmpty || waktuLog == null) {
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

      // Urutkan berdasarkan waktu terbaru
      newActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (newActivities.isEmpty) {
        _loadedAkunId = akunId;
        notifyListeners();
        return;
      }

      _activities.clear();
      _activities.addAll(newActivities);
      _loadedAkunId = akunId;
      notifyListeners();
    } catch (e) {
      debugPrint('[ActivityService] Error loading activities from DB: $e');
    }
  }

  void recordAuditActivity(
    String aktivitas, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final item = _activityFromAuditLog(
      id: 'local_${now.millisecondsSinceEpoch}',
      aktivitas: aktivitas,
      createdAt: now,
    );
    _activities.insert(0, item);
    notifyListeners();
  }

  ActivityItemData _activityFromAuditLog({
    required String id,
    required String aktivitas,
    required DateTime createdAt,
  }) {
    final normalized = aktivitas.toLowerCase();
    final timeText = _formatActivityTime(createdAt);

    if (normalized.contains('login')) {
      return ActivityItemData.info(
        id: id,
        title: aktivitas,
        subtitle: 'Log aktivitas akun Anda',
        timeText: timeText,
        status: 'Berhasil',
        createdAt: createdAt,
      );
    }

    if (normalized.contains('logout')) {
      return ActivityItemData.info(
        id: id,
        title: aktivitas,
        subtitle: 'Log aktivitas akun Anda',
        timeText: timeText,
        status: 'Berhasil',
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
        title: aktivitas,
        subtitle: 'Log aktivitas akun Anda',
        timeText: timeText,
        status: 'Diperbarui',
        createdAt: createdAt,
      );
    }

    if (normalized.contains('update data profil') || normalized.contains('profil')) {
      return ActivityItemData.info(
        id: id,
        title: aktivitas,
        subtitle: 'Log aktivitas akun Anda',
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
}
