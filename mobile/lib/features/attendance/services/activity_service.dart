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
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'checkin_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Check In Berhasil',
      subtitle: 'Anda berhasil melakukan check in',
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
    String? id,
    DateTime? createdAt,
  }) {
    return ActivityItemData(
      id: id ?? 'checkout_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Check Out Berhasil',
      subtitle: 'Anda berhasil melakukan check out',
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
  ActivityService._() {
    _initDefaultActivities();
  }

  static final ActivityService instance = ActivityService._();

  final List<ActivityItemData> _activities = [];

  List<ActivityItemData> get activities => List.unmodifiable(_activities);

  void _initDefaultActivities() {
    // Keep mock data as initial state before DB sync completes
    _activities.addAll([
      ActivityItemData.checkIn(
        timeText: 'Hari Ini, 08:25 WIB',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ActivityItemData.pengajuan(
        title: 'Pengajuan WFH',
        subtitle: 'Pengajuan work from home',
        timeText: 'Kemarin, 08.00 WIB',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      ),
      ActivityItemData.checkOut(
        timeText: 'Kemarin, 15.30 WIB',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  /// Memuat aktivitas absensi dan pengajuan nyata dari database
  Future<void> loadActivitiesFromDatabase(String pegawaiId) async {
    if (pegawaiId.isEmpty) return;

    try {
      final token = AuthState.instance.currentUser?.accessToken;
      final headers = {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${token != null && token.isNotEmpty ? token : SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final dio = Dio(BaseOptions(baseUrl: SupabaseConfig.url, headers: headers));

      // 1. Ambil data absensi terbaru
      final absensiResponse = await dio.get(
        '/rest/v1/absensi',
        queryParameters: {
          'pegawai_id': 'eq.$pegawaiId',
          'order': 'tanggal_absensi.desc,jam_checkin.desc',
          'limit': '5',
        },
      );

      // 2. Ambil data pengajuan terbaru
      final pengajuanResponse = await dio.get(
        '/rest/v1/pengajuan',
        queryParameters: {
          'pegawai_id': 'eq.$pegawaiId',
          'order': 'tanggal_pengajuan.desc',
          'limit': '5',
        },
      );

      final List<ActivityItemData> newActivities = [];

      // Parse absensi
      if (absensiResponse.statusCode == 200 && absensiResponse.data is List) {
        final list = absensiResponse.data as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;

          // Check In
          final checkInStr = map['jam_checkin']?.toString();
          if (checkInStr != null && checkInStr.isNotEmpty) {
            final checkInTime = DateTime.tryParse(checkInStr)?.toLocal();
            if (checkInTime != null) {
              newActivities.add(ActivityItemData.checkIn(
                id: 'checkin_${map['absensi_id'] ?? checkInStr}',
                timeText: _formatActivityTime(checkInTime),
                createdAt: checkInTime,
              ));
            }
          }

          // Check Out
          final checkOutStr = map['jam_checkout']?.toString();
          if (checkOutStr != null && checkOutStr.isNotEmpty) {
            final checkOutTime = DateTime.tryParse(checkOutStr)?.toLocal();
            if (checkOutTime != null) {
              newActivities.add(ActivityItemData.checkOut(
                id: 'checkout_${map['absensi_id'] ?? checkOutStr}',
                timeText: _formatActivityTime(checkOutTime),
                createdAt: checkOutTime,
              ));
            }
          }
        }
      }

      // Parse pengajuan
      if (pengajuanResponse.statusCode == 200 && pengajuanResponse.data is List) {
        final list = pengajuanResponse.data as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final dateStr = map['tanggal_pengajuan']?.toString() ?? '';
          final jenis = map['jenis_pengajuan']?.toString() ?? 'Pengajuan';
          final status = map['status_pengajuan']?.toString() ?? 'Pending';
          final id = map['pengajuan_id']?.toString() ?? dateStr;

          final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
          newActivities.add(ActivityItemData.pengajuan(
            id: 'pengajuan_$id',
            title: 'Pengajuan $jenis',
            subtitle: 'Pengajuan $jenis Anda sedang berstatus $status',
            timeText: _formatActivityDateOnly(date),
            status: status,
            createdAt: date,
          ));
        }
      }

      // Urutkan berdasarkan waktu terbaru
      newActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _activities.clear();
      _activities.addAll(newActivities);
      notifyListeners();
    } catch (e) {
      debugPrint('[ActivityService] Error loading activities from DB: $e');
    }
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

  String _formatActivityDateOnly(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dtDay = DateTime(dt.year, dt.month, dt.day);

    if (dtDay == today) {
      return 'Hari Ini';
    } else if (dtDay == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMM yyyy').format(dt);
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
