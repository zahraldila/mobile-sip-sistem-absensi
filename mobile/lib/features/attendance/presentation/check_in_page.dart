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

class _CheckInPageState extends State<CheckInPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AttendanceMode _currentApprovedMode;

  final List<_ModeTabInfo> _tabs = const [
    _ModeTabInfo(
      mode: AttendanceMode.wfo,
      label: 'WFO',
      icon: Icons.apartment_outlined,
      title: 'Work From Office',
    ),
    _ModeTabInfo(
      mode: AttendanceMode.wfh,
      label: 'WFH',
      icon: Icons.home_outlined,
      title: 'Work From Home',
    ),
    _ModeTabInfo(
      mode: AttendanceMode.wfc,
      label: 'WFC',
      icon: Icons.business_center_outlined,
      title: 'Work From Client',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentApprovedMode = widget.approvedMode ?? AttendanceMode.wfo;
    final initialIndex = _modeToIndex(_currentApprovedMode);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() => setState(() {}));
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _modeToIndex(AttendanceMode? mode) {
    if (mode == null) return 0;
    switch (mode) {
      case AttendanceMode.wfo:
        return 0;
      case AttendanceMode.wfh:
        return 1;
      case AttendanceMode.wfc:
        return 2;
    }
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _ModeTabBar(
            controller: _tabController,
            tabs: _tabs,
            approvedMode: _currentApprovedMode,
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner simulasi status pengajuan (membantu testing selama modul pengajuan dibuat)
          _ApprovalStatusNotice(
            approvedMode: _currentApprovedMode,
            onModeChanged: (newMode) {
              setState(() {
                _currentApprovedMode = newMode;
                _tabController.animateTo(_modeToIndex(newMode));
              });
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: WFO (selalu dapat diakses jika approved atau default)
                _isModeAllowed(AttendanceMode.wfo)
                    ? const CheckInWfoPage()
                    : _LockedModeView(
                        modeInfo: _tabs[0],
                        approvedMode: _currentApprovedMode,
                      ),

                // Tab 2: WFH
                _isModeAllowed(AttendanceMode.wfh)
                    ? const CheckInWfhPage()
                    : _LockedModeView(
                        modeInfo: _tabs[1],
                        approvedMode: _currentApprovedMode,
                      ),

                // Tab 3: WFC
                _isModeAllowed(AttendanceMode.wfc)
                    ? const CheckInWfcPage()
                    : _LockedModeView(
                        modeInfo: _tabs[2],
                        approvedMode: _currentApprovedMode,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabInfo {
  const _ModeTabInfo({
    required this.mode,
    required this.label,
    required this.icon,
    required this.title,
  });

  final AttendanceMode mode;
  final String label;
  final IconData icon;
  final String title;
}

/// Tab bar pill selector dengan badge status gembok/approval
class _ModeTabBar extends StatelessWidget {
  const _ModeTabBar({
    required this.controller,
    required this.tabs,
    required this.approvedMode,
  });

  final TabController controller;
  final List<_ModeTabInfo> tabs;
  final AttendanceMode approvedMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.pill,
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.pill,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          tabs: tabs.map((t) {
            final isApproved = t.mode == approvedMode;
            final isLocked = !isApproved && approvedMode != t.mode && t.mode != AttendanceMode.wfo;

            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 14),
                  const SizedBox(width: 4),
                  Text(t.label),
                  if (isLocked) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.lock_outline, size: 11, color: AppColors.textDisabled),
                  ] else if (isApproved && approvedMode != AttendanceMode.wfo) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle, size: 11, color: AppColors.success),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Tampilan jika pegawai memilih mode yang belum disetujui oleh admin
class _LockedModeView extends StatelessWidget {
  const _LockedModeView({
    required this.modeInfo,
    required this.approvedMode,
  });

  final _ModeTabInfo modeInfo;
  final AttendanceMode approvedMode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.warning, size: 32),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Mode ${modeInfo.label} Belum Disetujui',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Jadwal default kehadiran Anda adalah WFO. Untuk melakukan check-in ${modeInfo.title}, Anda harus mengajukan permohonan dan menunggu persetujuan (approval) dari admin.',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.medium,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Status saat ini: ${approvedMode.displayName}',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/submission'),
                  icon: const Icon(Icons.assignment_outlined, size: 18),
                  label: Text(
                    'Ajukan ${modeInfo.label} Sekarang',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar notifikasi status pengajuan & switcher testing mode
class _ApprovalStatusNotice extends StatelessWidget {
  const _ApprovalStatusNotice({
    required this.approvedMode,
    required this.onModeChanged,
  });

  final AttendanceMode approvedMode;
  final ValueChanged<AttendanceMode> onModeChanged;

  void _showSimulationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Simulasi Status Persetujuan Admin',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Ubah status untuk menguji tampilan mode kehadiran:',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SimulationOption(
                icon: Icons.apartment_outlined,
                title: 'WFO (Default / Belum Ada Approval)',
                subtitle: 'Tab WFH & WFC terkunci, WFO terbuka otomatis.',
                isSelected: approvedMode == AttendanceMode.wfo,
                onTap: () {
                  Navigator.pop(ctx);
                  onModeChanged(AttendanceMode.wfo);
                },
              ),
              const Divider(height: 1),
              _SimulationOption(
                icon: Icons.home_outlined,
                title: 'WFH (Pengajuan Disetujui)',
                subtitle: 'Tab WFH terbuka dan otomatis aktif.',
                isSelected: approvedMode == AttendanceMode.wfh,
                onTap: () {
                  Navigator.pop(ctx);
                  onModeChanged(AttendanceMode.wfh);
                },
              ),
              const Divider(height: 1),
              _SimulationOption(
                icon: Icons.business_center_outlined,
                title: 'WFC (Pengajuan Disetujui)',
                subtitle: 'Tab WFC terbuka dan otomatis aktif.',
                isSelected: approvedMode == AttendanceMode.wfc,
                onTap: () {
                  Navigator.pop(ctx);
                  onModeChanged(AttendanceMode.wfc);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWfo = approvedMode == AttendanceMode.wfo;

    return Container(
      width: double.infinity,
      color: isWfo
          ? AppColors.primary.withAlpha(12)
          : AppColors.success.withAlpha(15),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      child: Row(
        children: [
          Icon(
            isWfo ? Icons.info_outline : Icons.verified_user_outlined,
            size: 14,
            color: isWfo ? AppColors.primary : AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isWfo
                  ? 'Default WFO aktif. WFH/WFC terbuka saat pengajuan di-approve.'
                  : 'Pengajuan ${approvedMode.displayName} Disetujui Admin untuk hari ini.',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: isWfo ? AppColors.primary : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: () => _showSimulationSheet(context),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: isWfo ? AppColors.primary : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Simulasi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isWfo ? AppColors.primary : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationOption extends StatelessWidget {
  const _SimulationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}


