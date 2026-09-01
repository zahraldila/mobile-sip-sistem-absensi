import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:network_info_plus/network_info_plus.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/success_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_sistem_absensi_mobile/core/services/app_settings_service.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/data/notification_service.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/services/notification_read_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sip_sistem_absensi_mobile/core/utils/error_helpers.dart';

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

  bool _isConnected = true;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
    _initConnectivity();
    _loadTodayData();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    try {
      final results = await connectivity.checkConnectivity();
      _updateConnectionState(results);
    } catch (e) {
      debugPrint('[AttendanceHomePage] Error checking connectivity: $e');
    }

    _connectivitySubscription = connectivity.onConnectivityChanged.listen(_updateConnectionState);
  }

  void _updateConnectionState(List<ConnectivityResult> results) {
    if (!mounted) return;
    final isOffline = results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none);
    setState(() {
      _isConnected = !isOffline;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _connectivitySubscription.cancel();
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
  Future<void> _loadTodayData({bool isSilent = false}) async {
    if (!mounted) return;
    if (!isSilent) {
      setState(() {
        isLoading = true;
      });
    }

    final pegawaiId = AuthState.instance.currentUser?.pegawaiId ?? '';
    if (pegawaiId.isEmpty) {
      if (mounted && !isSilent) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    // Ambil data aktivitas terbaru dan branding settings dari database
    await Future.wait([
      ActivityService.instance.loadActivitiesFromDatabase(),
      AppSettingsService.instance.fetchSettings(),
    ]);

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

      // Derive boolean flags explicitly from DB values
      final hasCheckIn = jamCheckin != null && jamCheckin.isNotEmpty && jamCheckin != 'null';
      final hasCheckOut = jamCheckout != null && jamCheckout.isNotEmpty && jamCheckout != 'null';

      setState(() {
        if (skema == 'WFH') {
          currentMode = AttendanceMode.wfh;
          attendanceMethod = 'GPS & Foto Selfie (WFH)';
        } else if (skema == 'WFC') {
          currentMode = AttendanceMode.wfc;
          attendanceMethod = 'GPS & Foto Selfie (WFC)';
        } else {
          currentMode = AttendanceMode.wfo;
          final catatan = attendance['catatan']?.toString() ?? '';
          if (catatan.contains('WiFi')) {
            attendanceMethod = 'WiFi Kantor';
          } else if (catatan.contains('NFC')) {
            attendanceMethod = 'Sensor NFC Kantor';
          } else {
            attendanceMethod = 'NFC - Validasi Wi-Fi Perusahaan';
          }
        }

        // Set UI state according to presence of jam_checkin / jam_checkout
        isCheckedIn = hasCheckIn && !hasCheckOut;
        isAlreadyCheckedOut = hasCheckOut;

        if (hasCheckIn) {
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

    if (mounted && !isSilent) {
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
        _handleWfoCheckOutFlow(pegawaiId);
      } else {
        // Untuk WFH / WFC: buka halaman check-out dengan catatan kerja
        final result = await context.push<bool>('/attendance/check-out');
        if (result == true || result == null) {
          await _loadTodayData(isSilent: true);
        }
      }
    } else {
      // Guard: Cek apakah pegawai sudah pernah check-in hari ini di database
      final existing = await _attendanceService.fetchTodayAttendance(pegawaiId);
      if (existing != null) {
        final jamCheckin = existing['jam_checkin']?.toString();
        if (jamCheckin != null && jamCheckin.isNotEmpty && jamCheckin != 'null') {
          await _loadTodayData(isSilent: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Anda sudah melakukan check-in hari ini.'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (currentMode == AttendanceMode.wfo) {
        await _attemptWfoCheckIn(pegawaiId);
      } else {
        // Untuk WFH / WFC (setelah disetujui): buka halaman proses selfie & GPS
        if (!mounted) return;
        await context.push<bool>('/attendance/check-in', extra: currentMode);
        await _loadTodayData(isSilent: true);
      }
    }
  }

  Future<void> _attemptWfoCheckIn(String pegawaiId) async {
    // Tampilkan pilihan metode check-in (NFC atau WiFi) seperti desain bottom-sheet
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) {
        return CheckInMethodSelectionSheet(
          onNfcSelected: () {
            Navigator.pop(ctx);
            _triggerNfcCheckIn(pegawaiId);
          },
          onWiFiSelected: () {
            Navigator.pop(ctx);
            _triggerWiFiCheckIn(pegawaiId);
          },
        );
      },
    );
  }

  // Bottom sheet widget for choosing check-in method (WFO)
  // UI follows the project's style (rounded sheet, handle, cards)
  // This widget is placed here for file locality; can be moved to separate file later.
  // ignore: long-method
  Widget CheckInMethodSelectionSheet({
    required VoidCallback onNfcSelected,
    required VoidCallback onWiFiSelected,
  }) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E9EE),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Metode Check In WFO',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan pilih salah satu metode absensi kehadiran Anda di area kantor.',
              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            // NFC Card
            InkWell(
              onTap: onNfcSelected,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.nfc, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tap Kartu NFC', style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Tempelkan kartu pegawai ke bagian belakang ponsel Anda.', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            // WiFi Card
            InkWell(
              onTap: onWiFiSelected,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FBF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WiFi & Deteksi Lokasi', style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Verifikasi kehadiran otomatis dengan tersambung ke WiFi kantor dan deteksi lokasi.', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _isEarlyCheckOut() {
    if (todayEndTime.isEmpty) return false;
    try {
      final cleanEnd = todayEndTime.replaceAll(RegExp(r'[^0-9:]'), '').trim();
      final parts = cleanEnd.split(':');
      if (parts.length < 2) return false;

      final endHour = int.parse(parts[0]);
      final endMin = int.parse(parts[1]);

      final now = DateTime.now();
      final nowTotalMinutes = now.hour * 60 + now.minute;
      final endTotalMinutes = endHour * 60 + endMin;

      return nowTotalMinutes < endTotalMinutes;
    } catch (e) {
      debugPrint('[AttendanceHomePage] Error parsing end time: $e');
      return false;
    }
  }

  Future<void> _handleWfoCheckOutFlow(String pegawaiId) async {
    final isEarly = _isEarlyCheckOut();
    if (isEarly) {
      final reason = await _showEarlyCheckOutDialog();
      if (reason == null) return; // User cancelled
      _showCheckOutMethodSelection(pegawaiId, reason: reason);
    } else {
      _showCheckOutMethodSelection(pegawaiId);
    }
  }

  Future<String?> _showEarlyCheckOutDialog() {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => EarlyCheckOutSheet(endTime: todayEndTime),
    );
  }

  void _showCheckOutMethodSelection(String pegawaiId, {String? reason}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => CheckOutMethodSelectionSheet(
        onNfcSelected: () {
          Navigator.pop(context);
          _triggerNfcCheckOut(pegawaiId, reason: reason);
        },
        onWiFiSelected: () {
          Navigator.pop(context);
          // Tampilkan modal konfirmasi untuk WFO via WiFi
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
              title: Text(
                'Konfirmasi',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'Yakin ingin melakukan Check Out?',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _triggerWiFiCheckOut(pegawaiId, reason: reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                  child: const Text('Yakin'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _verifyWiFiBeforeNfc() async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      try {
        final status = await Permission.location.status;
        if (status.isDenied) {
          await Permission.location.request();
        }
      } catch (pe) {
        debugPrint('[AttendanceHomePage] Error requesting location permission: $pe');
      }

      final officeWiFis = await _attendanceService.fetchActiveOfficeWiFi();
      final info = NetworkInfo();
      String? currentSsid;
      try {
        currentSsid = await info.getWifiName();
        if (currentSsid != null) {
          currentSsid = currentSsid.trim().replaceAll('"', '').replaceAll("'", "");
        }
      } catch (e) {
        debugPrint('[AttendanceHomePage] Error reading WiFi SSID: $e');
      }

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      final officeSsids = officeWiFis
          .map((w) => w['ssid']?.toString().trim().replaceAll('"', '').replaceAll("'", "") ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      bool isMatched = false;
      if (currentSsid != null && currentSsid.isNotEmpty && currentSsid != '<unknown ssid>') {
        isMatched = officeSsids.any((officeSsid) =>
            officeSsid.toLowerCase() == currentSsid!.toLowerCase());
      }

      if (isMatched) {
        return true;
      } else {
        if (mounted) {
          _showWiFiFailureDialog(
            pegawaiId: '',
            detectedSsid: currentSsid,
            officeSsids: officeSsids,
            errorMsg: 'Untuk menggunakan scan NFC, perangkat Anda harus terhubung ke WiFi Kantor terlebih dahulu.',
          );
        }
        return false;
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa jaringan WiFi: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  void _triggerNfcCheckOut(String pegawaiId, {String? reason}) async {
    final wifiValid = await _verifyWiFiBeforeNfc();
    if (!wifiValid) return;

    if (!mounted) return;
    NfcTapDialog.show(
      context,
      isCheckOut: true,
      onValidateAndSubmit: (nfcUid) async {
        try {
          final isValid = await _attendanceService.validateNfcForPegawai(
            pegawaiId: pegawaiId,
            uid: nfcUid,
          );
          if (!isValid) {
            return 'Kartu NFC tidak terdaftar untuk akun Anda. Silakan gunakan kartu terdaftar.';
          }
          await _performWfoCheckOut(
            pegawaiId,
            method: 'Sensor NFC',
            reason: reason,
            nfcUid: nfcUid,
            showLoadingDialog: false,
            showSuccessDialog: false,
          );
          return null; // Berhasil
        } on AttendanceAuthenticationException {
          return 'Sesi login berakhir. Logout lalu login kembali.';
        } catch (e) {
          return 'Gagal melakukan check out: $e';
        }
      },
      onSuccess: (_) {
        // Data sudah tersinkronisasi saat submit
      },
    );
  }

  Future<void> _triggerWiFiCheckOut(String pegawaiId, {String? reason}) async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      try {
        final status = await Permission.location.status;
        if (status.isDenied) {
          await Permission.location.request();
        }
      } catch (pe) {
        debugPrint('[AttendanceHomePage] Error requesting location permission: $pe');
      }

      final officeWiFis = await _attendanceService.fetchActiveOfficeWiFi();

      final info = NetworkInfo();
      String? currentSsid;
      try {
        currentSsid = await info.getWifiName();
        if (currentSsid != null) {
          currentSsid = currentSsid.trim().replaceAll('"', '').replaceAll("'", "");
        }
      } catch (e) {
        debugPrint('[AttendanceHomePage] Error reading WiFi SSID: $e');
      }

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (officeWiFis.isEmpty) {
        _showWiFiFailureDialog(
          pegawaiId: pegawaiId,
          detectedSsid: currentSsid,
          officeSsids: [],
          errorMsg: 'Tidak ada WiFi Kantor aktif yang terdaftar di database.',
          isCheckOut: true,
          reason: reason,
        );
        return;
      }

      final officeSsids = officeWiFis
          .map((w) => w['ssid']?.toString().trim().replaceAll('"', '').replaceAll("'", "") ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      bool isMatched = false;
      if (currentSsid != null && currentSsid.isNotEmpty) {
        isMatched = officeSsids.any((officeSsid) =>
            officeSsid.toLowerCase() == currentSsid!.toLowerCase());
      }

      if (isMatched) {
        await _performWfoCheckOut(
          pegawaiId,
          method: 'WiFi Kantor ($currentSsid)',
          reason: reason,
        );
      } else {
        _showWiFiFailureDialog(
          pegawaiId: pegawaiId,
          detectedSsid: currentSsid,
          officeSsids: officeSsids,
          isCheckOut: true,
          reason: reason,
        );
      }
    } on AttendanceAuthenticationException {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login berakhir. Logout lalu login kembali.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      _showWiFiFailureDialog(
        pegawaiId: pegawaiId,
        detectedSsid: null,
        officeSsids: [],
        errorMsg: 'Terjadi kegagalan sistem deteksi WiFi: $e',
        isCheckOut: true,
        reason: reason,
      );
    }
  }

  Future<void> _performWfoCheckOut(
    String pegawaiId, {
    required String method,
    String? reason,
    String? nfcUid,
    bool showLoadingDialog = true,
    bool showSuccessDialog = true,
  }) async {
    BuildContext? dialogContext;
    if (showLoadingDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Ambil koordinat GPS perangkat secara best-effort (tidak memblokir jika gagal)
    final gps = await _getGpsCoordinates();

    try {
      final note = reason != null
          ? 'Check-out via $method (Alasan: $reason)'
          : 'Check-out via $method';
      final noteWithNfc = nfcUid == null ? note : '$note [UID NFC: $nfcUid]';

      await _attendanceService.checkOut(
        pegawaiId: pegawaiId,
        catatan: noteWithNfc,
        latitude: gps.latitude,
        longitude: gps.longitude,
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      await _loadTodayData(isSilent: true);

      if (mounted && showSuccessDialog) {
        showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Check Out Berhasil!',
            description: reason != null
                ? 'Anda berhasil check out lebih awal dengan alasan: $reason.'
                : 'Anda berhasil melakukan check out via $method.',
            onClose: () => Navigator.pop(context),
          ),
        );
      }
    } on AttendanceAuthenticationException {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login berakhir. Logout lalu login kembali.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHelpers.formatUserFriendlyMessage(e, isCheckOut: true)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Menjalankan Check In WFO menggunakan sensor/simulasi NFC secara aman.
  void _triggerNfcCheckIn(String pegawaiId) async {
    final wifiValid = await _verifyWiFiBeforeNfc();
    if (!wifiValid) return;

    if (!mounted) return;
    NfcTapDialog.show(
      context,
      isCheckOut: false,
      onValidateAndSubmit: (nfcUid) async {
        try {
          final isValid = await _attendanceService.validateNfcForPegawai(
            pegawaiId: pegawaiId,
            uid: nfcUid,
          );
          if (!isValid) {
            return 'Kartu NFC tidak terdaftar untuk akun Anda. Silakan gunakan kartu terdaftar.';
          }
          await _performWfoCheckIn(
            pegawaiId,
            method: 'Sensor NFC',
            nfcUid: nfcUid,
            showLoadingDialog: false,
            showSuccessDialog: false,
          );
          return null; // Berhasil
        } on AttendanceAuthenticationException {
          return 'Sesi login berakhir. Logout lalu login kembali.';
        } catch (e) {
          return 'Gagal melakukan check in: $e';
        }
      },
      onSuccess: (_) {
        // Data sudah tersinkronisasi saat submit
      },
    );
  }

  /// Menjalankan verifikasi WiFi untuk Check In WFO.
  Future<bool> _triggerWiFiCheckIn(String pegawaiId) async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );

    // Memberi waktu 100ms agar dialog route didaftarkan sepenuhnya ke Navigator
    await Future.delayed(const Duration(milliseconds: 100));

    List<Map<String, dynamic>> officeWiFis = [];
    String? currentSsid;
    bool hasDetectionError = false;
    String? detectionErrorMsg;

    try {
      // Minta izin lokasi di Android agar diperbolehkan membaca SSID WiFi
      try {
        final status = await Permission.location.status;
        if (status.isDenied) {
          await Permission.location.request();
        }
      } catch (pe) {
        debugPrint('[AttendanceHomePage] Error requesting location permission: $pe');
      }

      // 1. Ambil daftar wifi kantor aktif dari database
      officeWiFis = await _attendanceService.fetchActiveOfficeWiFi();

      // 2. Baca SSID WiFi perangkat lokal
      final info = NetworkInfo();
      try {
        currentSsid = await info.getWifiName();
        if (currentSsid != null) {
          currentSsid = currentSsid.trim().replaceAll('"', '').replaceAll("'", "");
        }
      } catch (e) {
        debugPrint('[AttendanceHomePage] Error reading WiFi SSID: $e');
      }
    } catch (e) {
      hasDetectionError = true;
      detectionErrorMsg = 'Terjadi kegagalan sistem deteksi WiFi: $e';
    } finally {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!); // Tutup loading dialog secara aman
      }
    }

    if (hasDetectionError) {
      _showWiFiFailureDialog(
        pegawaiId: pegawaiId,
        detectedSsid: null,
        officeSsids: [],
        errorMsg: detectionErrorMsg,
      );
      return false;
    }

    if (officeWiFis.isEmpty) {
      _showWiFiFailureDialog(
        pegawaiId: pegawaiId,
        detectedSsid: currentSsid,
        officeSsids: [],
        errorMsg: 'Tidak ada WiFi Kantor aktif yang terdaftar di database.',
      );
      return false;
    }

    // Ambil seluruh nama SSID kantor yang aktif
    final officeSsids = officeWiFis
        .map((w) => w['ssid']?.toString().trim().replaceAll('"', '').replaceAll("'", "") ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    // 3. Cocokkan SSID ponsel dengan daftar SSID kantor
    bool isMatched = false;
    if (currentSsid != null && currentSsid.isNotEmpty && currentSsid != '<unknown ssid>') {
      isMatched = officeSsids.any((officeSsid) =>
          officeSsid.toLowerCase() == currentSsid!.toLowerCase());
    }

    if (isMatched) {
      // Perangkat terhubung ke WiFi kantor aktif! Lakukan check in via WiFi.
      try {
        await _performWfoCheckIn(pegawaiId, method: 'WiFi Kantor ($currentSsid)');
      } catch (e) {
        debugPrint('[AttendanceHomePage] Error in _performWfoCheckIn: $e');
      }
      return true; // Return true agar TIDAK me-redirect ke NFC
    } else {
      // Tidak cocok/gagal deteksi. Tampilkan dialog failure WiFi.
      _showWiFiFailureDialog(
        pegawaiId: pegawaiId,
        detectedSsid: currentSsid,
        officeSsids: officeSsids,
      );
      return false;
    }
  }

  /// Mengambil koordinat GPS perangkat secara best-effort.
  /// Jika GPS tidak tersedia atau gagal, mengembalikan null tanpa melempar exception.
  Future<({double? latitude, double? longitude})> _getGpsCoordinates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return (latitude: null, longitude: null);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (latitude: null, longitude: null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      debugPrint('[AttendanceHomePage] GPS capture failed (best-effort): $e');
      return (latitude: null, longitude: null);
    }
  }

  /// Eksekusi pengiriman data check-in WFO ke database dan tampilkan SuccessDialog.
  Future<void> _performWfoCheckIn(
    String pegawaiId, {
    required String method,
    String? nfcUid,
    bool showLoadingDialog = true,
    bool showSuccessDialog = true,
  }) async {
    BuildContext? dialogContext;
    if (showLoadingDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Ambil koordinat GPS perangkat secara best-effort (tidak memblokir jika gagal)
    final gps = await _getGpsCoordinates();

    try {
      await _attendanceService.checkIn(
        pegawaiId: pegawaiId,
        skemaKerja: 'WFO',
        jadwalId: todayJadwalId,
        statusKehadiran: 'Hadir',
        latitude: gps.latitude,
        longitude: gps.longitude,
        catatan: nfcUid == null
            ? 'Check-in via $method'
            : 'Check-in via $method [UID NFC: $nfcUid]',
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!); // Tutup loading dialog secara aman menggunakan dialogContext
      }

      // Optimistic UI update: tampilkan status sudah check-in segera untuk responsifitas.
      final now = DateTime.now();
      final displayTime = DateFormat('HH:mm').format(now);
      if (mounted) {
        setState(() {
          isCheckedIn = true;
          checkInTime = displayTime;
          attendanceMethod = method;
        });

        // Tampilkan SuccessDialog jika diminta (misal dari WiFi checkin)
        if (showSuccessDialog) {
          showDialog(
            context: context,
            builder: (context) => SuccessDialog(
              title: 'Check In Berhasil!',
              description: 'Anda berhasil melakukan check in via $method.',
              onClose: () => Navigator.pop(context),
            ),
          );
        }
      }

      // Lakukan sinkronisasi / polling di background untuk memastikan data server tercermin
      // tanpa menahan UI atau dialog success.
      Future(() async {
        const int maxAttempts = 6;
        int attempt = 0;
        bool found = false;
        while (attempt < maxAttempts && !found) {
          try {
            final existing = await _attendanceService.fetchTodayAttendance(pegawaiId);
            final jamCheckin = existing?['jam_checkin']?.toString();
            if (jamCheckin != null && jamCheckin.isNotEmpty && jamCheckin != 'null') {
              found = true;
              break;
            }
          } catch (e) {
            debugPrint('[AttendanceHomePage] Background polling fetchTodayAttendance attempt $attempt failed: $e');
          }
          attempt += 1;
          await Future.delayed(const Duration(milliseconds: 400));
        }
        if (mounted) {
          await _loadTodayData(isSilent: true);
        }
      });
    } on AttendanceAuthenticationException {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login berakhir. Logout lalu login kembali.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!); // Tutup loading dialog secara aman menggunakan dialogContext
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHelpers.formatUserFriendlyMessage(e, isCheckOut: false)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Menampilkan bottom sheet jika verifikasi WiFi kantor tidak cocok.
  void _showWiFiFailureDialog({
    required String pegawaiId,
    required String? detectedSsid,
    required List<String> officeSsids,
    String? errorMsg,
    bool isCheckOut = false,
    String? reason,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => WiFiFailureSheet(
        detectedSsid: detectedSsid,
        officeSsids: officeSsids,
        errorMsg: errorMsg,
      ),
    );
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
              if (!_isConnected)
                Container(
                  color: const Color(0xFFFEE2E2),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tidak ada koneksi internet. Menampilkan data terakhir yang tersimpan.',
                          style: AppTypography.textTheme.bodySmall?.copyWith(color: const Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isLoading) ...[
                const SizedBox(height: 200),
                Center(
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
                  todayStartTime: todayStartTime,
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
    required this.todayStartTime,
    this.isAlreadyCheckedOut = false,
    super.key,
  });

  final String currentTime;
  final bool isCheckedIn;
  final String checkInTime;
  final String attendanceMethod;
  final VoidCallback onActionPressed;
  final bool isAlreadyCheckedOut;
  final String todayStartTime;

  String? _calculateLateness(String checkIn, String start) {
    try {
      final cleanCheckIn = checkIn.replaceAll(RegExp(r'[^0-9:]'), '').trim();
      final cleanStart = start.replaceAll(RegExp(r'[^0-9:]'), '').trim();

      final checkInParts = cleanCheckIn.split(':');
      final startParts = cleanStart.split(':');

      if (checkInParts.length < 2 || startParts.length < 2) return null;

      final checkInHour = int.parse(checkInParts[0]);
      final checkInMin = int.parse(checkInParts[1]);

      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);

      final checkInTotalMinutes = checkInHour * 60 + checkInMin;
      final startTotalMinutes = startHour * 60 + startMin;

      final diffMinutes = checkInTotalMinutes - startTotalMinutes;

      if (diffMinutes <= 0) return null;

      final diffHour = diffMinutes ~/ 60;
      final diffMin = diffMinutes % 60;

      if (diffHour > 0) {
        return 'Terlambat $diffHour jam $diffMin menit';
      } else {
        return 'Terlambat $diffMin menit';
      }
    } catch (e) {
      debugPrint('[AttendanceStatusCard] Error calculating lateness: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final latenessText = isCheckedIn && !isAlreadyCheckedOut
        ? _calculateLateness(checkInTime, todayStartTime)
        : null;
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
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: isAlreadyCheckedOut
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
                                if (latenessText != null)
                                  TextSpan(
                                    text: ' ($latenessText)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.danger,
                                    ),
                                  ),
                              ],
                            ),
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
                    backgroundColor: AppColors.primary,
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

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _checkUnreadStatus();
  }

  Future<void> _checkUnreadStatus() async {
    final user = AuthState.instance.currentUser;
    final pegawaiId = user?.pegawaiId ?? '';
    if (pegawaiId.isEmpty) return;

    try {
      final service = NotificationService();
      final readService = NotificationReadService();
      final list = await service.fetchNotifications(pegawaiId);
      if (list.isEmpty) {
        if (mounted) setState(() => _hasUnread = false);
        return;
      }

      final ids = list.map((n) => n.notifikasiId).toList();
      final statuses = await readService.fetchReadStatuses(ids);
      final hasUnread = list.any((n) => statuses[n.notifikasiId] != true);
      if (mounted) {
        setState(() => _hasUnread = hasUnread);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          await context.push('/notifications');
          _checkUnreadStatus();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.textBlack,
                size: 24,
              ),
              if (_hasUnread)
                Positioned(
                  top: 1,
                  right: 2,
                  child: Container(
                    width: 8.5,
                    height: 8.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33EF4444),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
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

class CheckInMethodSelectionSheet extends StatelessWidget {
  final VoidCallback onNfcSelected;
  final VoidCallback onWiFiSelected;

  const CheckInMethodSelectionSheet({
    super.key,
    required this.onNfcSelected,
    required this.onWiFiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Pilih Metode Check In WFO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Silakan pilih salah satu metode absensi kehadiran Anda di area kantor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Option 1: Tap NFC
          _buildMethodCard(
            icon: Icons.nfc_rounded,
            iconColor: const Color(0xFF2563EB), // Blue
            bgColor: const Color(0xFFEFF6FF),
            title: 'Tap Kartu NFC',
            description: 'Tempelkan kartu pegawai ke bagian belakang ponsel Anda.',
            onTap: onNfcSelected,
          ),
          const SizedBox(height: 16),

          // Option 2: WiFi Kantor
          _buildMethodCard(
            icon: Icons.wifi_rounded,
            iconColor: const Color(0xFF059669), // Green
            bgColor: const Color(0xFFECFDF5),
            title: 'WiFi & Deteksi Lokasi',
            description: 'Verifikasi WiFi dan deteksi lokasi perangkat.',
            onTap: onWiFiSelected,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckOutMethodSelectionSheet extends StatelessWidget {
  final VoidCallback onNfcSelected;
  final VoidCallback onWiFiSelected;

  const CheckOutMethodSelectionSheet({
    super.key,
    required this.onNfcSelected,
    required this.onWiFiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Pilih Metode Check Out WFO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Silakan verifikasi kepulangan Anda menggunakan salah satu metode di bawah ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Option 1: Tap NFC
          _buildMethodCard(
            icon: Icons.nfc_rounded,
            iconColor: const Color(0xFF2563EB), // Blue
            bgColor: const Color(0xFFEFF6FF),
            title: 'Tap Kartu NFC',
            description: 'Tempelkan kartu pegawai ke bagian belakang ponsel Anda.',
            onTap: onNfcSelected,
          ),
          const SizedBox(height: 16),

          // Option 2: WiFi Kantor
          _buildMethodCard(
            icon: Icons.wifi_rounded,
            iconColor: const Color(0xFF059669), // Green
            bgColor: const Color(0xFFECFDF5),
            title: 'WiFi & Deteksi Lokasi',
            description: 'Verifikasi WiFi dan deteksi lokasi perangkat.',
            onTap: onWiFiSelected,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class EarlyCheckOutSheet extends StatefulWidget {
  final String endTime;

  const EarlyCheckOutSheet({
    super.key,
    required this.endTime,
  });

  @override
  State<EarlyCheckOutSheet> createState() => _EarlyCheckOutSheetState();
}

class _EarlyCheckOutSheetState extends State<EarlyCheckOutSheet> {
  String selectedCategory = 'Dinas Luar / Bertemu Klien';
  final textController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Warning Icon & Title Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7), // Light amber
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFD97706), // Amber
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Check Out Lebih Awal',
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subtitle Warning Text
            Text(
              'Jam kerja Anda baru berakhir pada ${widget.endTime}. Apakah Anda yakin ingin melakukan check-out sekarang?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Label 1: Alasan Check Out
            Text(
              'Alasan Check Out',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Dropdown Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                    'Dinas Luar / Bertemu Klien',
                    'Sakit / Kurang Sehat',
                    'Keperluan Pribadi Mendesak',
                    'Lainnya',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedCategory = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Label 2: Keterangan
            Text(
              'Keterangan Tambahan',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // TextFormField
            TextFormField(
              controller: textController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: selectedCategory == 'Lainnya'
                    ? 'Tulis alasan rinci Anda di sini...'
                    : 'Tambahkan catatan jika ada (opsional)...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (selectedCategory == 'Lainnya' && (value == null || value.trim().isEmpty)) {
                  return 'Keterangan wajib diisi untuk alasan Lainnya';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() == true) {
                        final detail = textController.text.trim();
                        final fullReason = detail.isNotEmpty
                            ? '$selectedCategory: $detail'
                            : selectedCategory;
                        Navigator.pop(context, fullReason);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lanjut',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WiFiFailureSheet extends StatelessWidget {
  final String? detectedSsid;
  final List<String> officeSsids;
  final String? errorMsg;
  final bool isCheckOut;

  const WiFiFailureSheet({
    super.key,
    required this.detectedSsid,
    required this.officeSsids,
    this.errorMsg,
    this.isCheckOut = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7), // Light amber
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFD97706), // Amber
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WiFi Kantor Belum Sesuai',
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCheckOut ? 'Verifikasi Check Out WFO' : 'Verifikasi Absensi WFO',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtitle Message
          Text(
            errorMsg ??
                'Untuk menggunakan scan NFC, perangkat Anda harus terhubung ke salah satu jaringan WiFi Kantor resmi.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Card Detail
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WiFi Terdeteksi
                Row(
                  children: [
                    Icon(
                      detectedSsid != null && detectedSsid!.isNotEmpty
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      size: 18,
                      color: detectedSsid != null && detectedSsid!.isNotEmpty
                          ? const Color(0xFFD97706)
                          : Colors.red[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WiFi Terdeteksi Perangkat:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    (detectedSsid != null && detectedSsid!.isNotEmpty)
                        ? '"$detectedSsid"'
                        : '(Tidak Terdeteksi / Izin Lokasi Matikan)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: (detectedSsid != null && detectedSsid!.isNotEmpty)
                          ? Colors.black87
                          : Colors.red[600],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 14),

                // WiFi Kantor Terdaftar
                Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WiFi Kantor Terdaftar:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: officeSsids.isNotEmpty
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: officeSsids.map((ssid) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Text(
                                ssid,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Text(
                          '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
