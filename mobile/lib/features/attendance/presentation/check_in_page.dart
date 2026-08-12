import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/domain/models/attendance_mode.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/check_in_wfc_page.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/check_in_wfh_page.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/check_in_wfo_page.dart';

/// Halaman wrapper utama untuk proses Check In.
/// 
/// Aturan Bisnis:
/// - Default kehadiran pegawai adalah WFO (Work From Office).
/// - Mode WFH dan WFC hanya dapat diakses jika sudah ada pengajuan
///   yang disetujui (approved) oleh admin untuk hari ini.
/// - Jika belum diapprove, tab WFH/WFC akan menampilkan informasi
///   terkunci beserta tombol shortcut ke menu Pengajuan.
class CheckInPage extends StatefulWidget {
  const CheckInPage({
    this.approvedMode,
    super.key,
  });

  /// Mode kehadiran yang disetujui oleh admin untuk hari ini (Default: WFO)
  final AttendanceMode? approvedMode;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late AttendanceMode _currentApprovedMode;

  @override
  void initState() {
    super.initState();
    _currentApprovedMode = widget.approvedMode ?? AttendanceMode.wfo;
  }

  bool _isModeAllowed(AttendanceMode? mode) {
    if (mode == null) return false;
    // Mode yang disetujui selalu diperbolehkan
    if (mode == _currentApprovedMode) return true;
    // Jika tidak ada pengajuan lain, hanya WFO yang diizinkan (default kantor)
    if (_currentApprovedMode == AttendanceMode.wfo && mode == AttendanceMode.wfo) {
      return true;
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check In Kehadiran',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              _currentApprovedMode == AttendanceMode.wfo
                  ? 'Jadwal Hari Ini: WFO (Default)'
                  : 'Jadwal Hari Ini: ${_currentApprovedMode.displayName} (Disetujui Admin)',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: _currentApprovedMode == AttendanceMode.wfo
                    ? AppColors.textSecondary
                    : AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _buildCurrentModeContent(),
    );
  }

  Widget _buildCurrentModeContent() {
    if (_isModeAllowed(AttendanceMode.wfo)) {
      return const CheckInWfoPage();
    }
    if (_isModeAllowed(AttendanceMode.wfh)) {
      return const CheckInWfhPage();
    }
    if (_isModeAllowed(AttendanceMode.wfc)) {
      return const CheckInWfcPage();
    }

    return const Center(child: Text('Mode tidak tersedia'));
  }
}



/// Bar notifikasi status pengajuan & switcher testing mode


