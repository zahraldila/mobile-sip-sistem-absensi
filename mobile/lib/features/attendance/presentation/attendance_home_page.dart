import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/domain/models/attendance_mode.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/widgets/nfc_tap_dialog.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/services/activity_service.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/services/attendance_service.dart';

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  late Timer _timer;
  late String _currentTime;

  final _attendanceService = AttendanceService();

  // Mode kehadiran hari ini (Default: WFO)
  AttendanceMode currentMode = AttendanceMode.wfo;

  // State absensi
  bool isCheckedIn = false;
  String checkInTime = '08:25';
  String attendanceMethod = 'NFC - Validasi Wi-Fi Perusahaan';

  // State tambahan untuk data dinamis database
  int? todayJadwalId;
  String todayStartTime = '08:30 WIB';
  String todayEndTime = '15:30 WIB';
  bool isAlreadyCheckedOut = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
    _loadTodayData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm').format(now);
    setState(() {
      _currentTime = formattedTime;
    });
  }

  /// Mengambil data jadwal kerja dan status absensi secara dinamis dari Supabase.
  Future<void> _loadTodayData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    final pegawaiId = AuthState.instance.currentUser?.pegawaiId ?? '';
    if (pegawaiId.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    // 1. Ambil Jadwal Kerja Aktif Hari Ini
    final schedule = await _attendanceService.fetchTodaySchedule();
    if (schedule != null && mounted) {
      todayJadwalId = int.tryParse(schedule['jadwal_id']?.toString() ?? '');
      final rawMasuk = schedule['jam_masuk']?.toString() ?? '08:30';
      final rawPulang = schedule['jam_pulang']?.toString() ?? '15:30';
      
      final masukTime = rawMasuk.split(':').take(2).join(':');
      final pulangTime = rawPulang.split(':').take(2).join(':');
      
      setState(() {
        todayStartTime = '$masukTime WIB';
        todayEndTime = '$pulangTime WIB';
      });
    }

    // 2. Cek Pengajuan WFH/WFC yang Disetujui Hari Ini
    final submission = await _attendanceService.fetchTodayApprovedSubmission(pegawaiId);
    AttendanceMode approvedMode = AttendanceMode.wfo;
    if (submission != null) {
      final jenis = submission['jenis_pengajuan']?.toString().toLowerCase() ?? '';
      if (jenis.contains('wfh')) {
        approvedMode = AttendanceMode.wfh;
      } else if (jenis.contains('wfc')) {
        approvedMode = AttendanceMode.wfc;
      }
    }

    // 3. Ambil Status Absensi Hari Ini
    final attendance = await _attendanceService.fetchTodayAttendance(pegawaiId);
    if (attendance != null && mounted) {
      final jamCheckin = attendance['jam_checkin']?.toString();
      final jamCheckout = attendance['jam_checkout']?.toString();
      final skema = attendance['skema_kerja']?.toString().toUpperCase() ?? 'WFO';
      
      setState(() {
        if (skema == 'WFH') {
          currentMode = AttendanceMode.wfh;
          attendanceMethod = 'GPS & Foto Selfie (WFH)';
        } else if (skema == 'WFC') {
          currentMode = AttendanceMode.wfc;
          attendanceMethod = 'GPS & Foto Selfie (WFC)';
        } else {
          currentMode = AttendanceMode.wfo;
          attendanceMethod = 'NFC - Validasi Wi-Fi Perusahaan';
        }

        if (jamCheckin != null) {
          isCheckedIn = jamCheckout == null;
          isAlreadyCheckedOut = jamCheckout != null;
          
          final parsedCheckIn = DateTime.tryParse(jamCheckin)?.toLocal();
          if (parsedCheckIn != null) {
            checkInTime = DateFormat('HH:mm').format(parsedCheckIn);
          }
        }
      });
    } else if (mounted) {
      setState(() {
        currentMode = approvedMode;
        isCheckedIn = false;
        isAlreadyCheckedOut = false;
        if (currentMode == AttendanceMode.wfh) {
          attendanceMethod = 'GPS & Foto Selfie (WFH)';
        } else if (currentMode == AttendanceMode.wfc) {
          attendanceMethod = 'GPS & Foto Selfie (WFC)';
        } else {
          attendanceMethod = 'NFC - Validasi Wi-Fi Perusahaan';
        }
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _onActionPressed() async {
    final pegawaiId = AuthState.instance.currentUser?.pegawaiId ?? '';
    if (pegawaiId.isEmpty) return;

    if (isCheckedIn) {
      if (currentMode == AttendanceMode.wfo) {
        // Untuk WFO: saat Check Out juga tampilkan Pop Up NFC Tap
        NfcTapDialog.show(
          context,
          isCheckOut: true,
          onSuccess: () async {
            try {
              await _attendanceService.checkOut(
                pegawaiId: pegawaiId,
                catatan: 'Check-out WFO',
              );
              await _loadTodayData();
              ActivityService.instance.recordCheckOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Check Out WFO Berhasil! Sampai jumpa besok.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal mencatat Check Out: $e'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      } else {
        // Untuk WFH / WFC: buka halaman check-out dengan catatan kerja
        final result = await context.push<bool>('/attendance/check-out');
        if (result == true) {
          await _loadTodayData();
        }
      }
    } else {
      if (currentMode == AttendanceMode.wfo) {
        // Untuk WFO: langsung tampilkan Pop Up NFC sesuai desain
        NfcTapDialog.show(
          context,
          isCheckOut: false,
          onSuccess: () async {
            try {
              await _attendanceService.checkIn(
                pegawaiId: pegawaiId,
                skemaKerja: 'WFO',
                jadwalId: todayJadwalId,
                statusKehadiran: 'Hadir',
              );
              await _loadTodayData();
              ActivityService.instance.recordCheckIn();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Check In WFO Berhasil ($checkInTime WIB)!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal mencatat Check In: $e'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      } else {
        // Untuk WFH / WFC (setelah disetujui): buka halaman proses selfie & GPS
        final result = await context.push<bool>('/attendance/check-in', extra: currentMode);
        if (result == true) {
          await _loadTodayData();
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTodayData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 24, bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLoading) ...[
                const SizedBox(height: 200),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                _HomeHeader(name: AuthState.instance.currentUser?.namaPegawai ?? 'Farida'),
                const SizedBox(height: AppSpacing.xxl),

                AttendanceStatusCard(
                  currentTime: _currentTime,
                  isCheckedIn: isCheckedIn,
                  checkInTime: checkInTime,
                  attendanceMethod: attendanceMethod,
                  onActionPressed: _onActionPressed,
                  isAlreadyCheckedOut: isAlreadyCheckedOut,
                ),

                const SizedBox(height: AppSpacing.xxl),
                WorkScheduleCard(
                  workType: currentMode.fullName,
                  startTime: todayStartTime,
                  endTime: todayEndTime,
                ),

                const SizedBox(height: AppSpacing.xxl),
                const RecentActivityCard(),
                const SizedBox(height: 96),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Rest of the widgets remain unchanged as they were correctly defined ---

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hai, $name',
                style: AppTypography.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Selamat datang kembali!',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.greeting,
                ),
              ),
            ],
          ),
        ),
        const NotificationButton(),
      ],
    );
  }
}

class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({
    required this.currentTime,
    required this.isCheckedIn,
    required this.checkInTime,
    required this.attendanceMethod,
    required this.onActionPressed,
    this.isAlreadyCheckedOut = false,
    super.key,
  });

  final String currentTime;
  final bool isCheckedIn;
  final String checkInTime;
  final String attendanceMethod;
  final VoidCallback onActionPressed;
  final bool isAlreadyCheckedOut;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Hari Ini',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isAlreadyCheckedOut) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 24,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Sudah Check Out',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isCheckedIn) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            size: 24,
                            color: Color(0xFF9E7710),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6EFE0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Belum Check In',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B6E1F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 24,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F8EE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Sudah Check In',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF27AE60),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentTime,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'WIB',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAlreadyCheckedOut
                              ? 'Sudah Check Out'
                              : (isCheckedIn
                                  ? 'Check In $checkInTime WIB'
                                  : 'Belum Check In'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 115,
                height: 115,
                child: AttendanceIllustration(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Alert banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAlreadyCheckedOut
                  ? const Color(0xFFF1F5F9)
                  : (isCheckedIn
                      ? const Color(0xFFE6F8EE)
                      : const Color(0xFFFDE8E9)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isAlreadyCheckedOut
                      ? Icons.check_circle_outline_rounded
                      : (isCheckedIn
                          ? Icons.verified_user_outlined
                          : Icons.shield_outlined),
                  color: isAlreadyCheckedOut
                      ? AppColors.textSecondary
                      : (isCheckedIn
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFEB5757)),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAlreadyCheckedOut
                        ? 'Absensi selesai hari ini'
                        : (isCheckedIn
                            ? 'Metode: $attendanceMethod'
                            : 'Anda Belum Melakukan Check In'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isAlreadyCheckedOut
                          ? AppColors.textSecondary
                          : (isCheckedIn
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFEB5757)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF5)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAlreadyCheckedOut
                          ? 'Kerja Keras Selesai!'
                          : (isCheckedIn ? 'Belum Check Out' : 'Belum Check In'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAlreadyCheckedOut
                          ? 'Terima kasih atas kerja keras Anda hari ini. Sampai jumpa esok hari!'
                          : (isCheckedIn
                              ? 'Jangan lupa melakukan check out setelah jam kerja selesai.'
                              : 'Jangan lupa melakukan check in sebelum jam masuk.'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (!isAlreadyCheckedOut)
                ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E60F2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    isCheckedIn ? 'Check Out' : 'Check In',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class WorkScheduleCard extends StatelessWidget {
  const WorkScheduleCard({
    required this.workType,
    required this.startTime,
    required this.endTime,
    super.key,
  });

  final String workType;
  final String startTime;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF2F80ED),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Hari Ini',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workType,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
              ),
              const ScheduleBadge(label: 'Jadwal Tetap'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ScheduleItem(
                  title: 'Jam Masuk',
                  time: startTime,
                  iconColor: const Color(0xFF27AE60),
                  iconBgColor: const Color(0xFFE6F8EE),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ScheduleItem(
                  title: 'Jam Pulang',
                  time: endTime,
                  iconColor: const Color(0xFFEB5757),
                  iconBgColor: const Color(0xFFFDECEE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aktivitas Terbaru',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.push('/history'),
                child: Text(
                  'Lihat Semua >',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ListenableBuilder(
            listenable: ActivityService.instance,
            builder: (context, _) {
              final activities = ActivityService.instance.activities.take(3).toList();
              if (activities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'Belum ada aktivitas',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }
              return Column(
                children: activities
                    .map((activity) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: ActivityItem(data: activity),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  const ActivityItem({required this.data, super.key});

  final ActivityItemData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, color: data.iconColor, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  color: const Color(0xFF828282),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: data.timePillBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      data.timeText,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: data.statusBgColor,
            border: Border.all(
              color: data.statusColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            data.statusLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: data.statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/notifications'),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.notifications_none, color: AppColors.textBlack, size: 24),
        ),
      ),
    );
  }
}

class PrimaryCard extends StatelessWidget {
  const PrimaryCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x260F172A), blurRadius: 3, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: _withAlpha(color, 0.14),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.text,
    required this.color,
    required this.icon,
    super.key,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _withAlpha(color, 0.14),
        borderRadius: AppRadius.medium,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _withAlpha(Color color, double opacity) {
  return color.withAlpha((opacity * 255).round());
}

class ScheduleBadge extends StatelessWidget {
  const ScheduleBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFEDF2FE),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: const Color(0xFF2F80ED),
        ),
      ),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({
    required this.title,
    required this.time,
    required this.iconColor,
    required this.iconBgColor,
    super.key,
  });

  final String title;
  final String time;
  final Color iconColor;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBDD8F4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class AttendanceIllustration extends StatelessWidget {
  const AttendanceIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Center(
        child: Image.asset('assets/images/attendance_illustration.png'),
      ),
    );
  }
}