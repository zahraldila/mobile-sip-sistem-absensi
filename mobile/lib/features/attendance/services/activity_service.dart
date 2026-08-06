import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      ActivityItemData.info(
        title: 'Perubahan Jadwal',
        subtitle: 'Jadwal kerja anda telah diperbarui',
        timeText: '2 hari lalu, 09.15 WIB',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ActivityItemData.info(
        title: 'Perubahan Jadwal',
        subtitle: 'Jadwal kerja anda telah diperbarui',
        timeText: '2 hari lalu, 09.15 WIB',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      ),
    ]);
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
