import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

import 'package:sip_sistem_absensi_mobile/features/attendance/services/attendance_service.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/data/datasources/profile_remote_datasource.dart';

/// UI Check In mode Work From Home (WFH).
/// Metode: GPS/Lokasi + Selfie kamera.
class CheckInWfhPage extends StatefulWidget {
  const CheckInWfhPage({super.key});

  @override
  State<CheckInWfhPage> createState() => _CheckInWfhPageState();
}

class _CheckInWfhPageState extends State<CheckInWfhPage> {
  _DetectionStatus _locationStatus = _DetectionStatus.idle;
  _DetectionStatus _selfieStatus = _DetectionStatus.idle;
  String _locationText = '';
  double? _latitude;
  double? _longitude;
  String? _selfiePath;
  String? _uploadedSelfiePath;
  final ImagePicker _picker = ImagePicker();

  bool get _canSubmit =>
      _locationStatus == _DetectionStatus.success &&
      _selfieStatus == _DetectionStatus.success;

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showSnackbar('Aktifkan layanan lokasi terlebih dahulu', isError: true);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showSnackbar('Izin lokasi ditolak', isError: true);
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar('Izin lokasi ditolak permanen. Buka pengaturan aplikasi.', isError: true);
      return false;
    }

    return true;
  }
  Future<void> _detectLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    setState(() => _locationStatus = _DetectionStatus.loading);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationText = 'Lat ${position.latitude.toStringAsFixed(6)}, Lon ${position.longitude.toStringAsFixed(6)}';
        _locationStatus = _DetectionStatus.success;
      });
    } catch (e) {
      setState(() => _locationStatus = _DetectionStatus.error);
      _showSnackbar('Gagal mendeteksi lokasi: $e', isError: true);
    }
  }

  Future<void> _takeSelfie() async {
    if (_locationStatus != _DetectionStatus.success) {
      _showSnackbar('Deteksi lokasi terlebih dahulu', isError: true);
      return;
    }

    setState(() => _selfieStatus = _DetectionStatus.loading);
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (!mounted) return;
      if (pickedFile == null) {
        setState(() => _selfieStatus = _DetectionStatus.idle);
        return;
      }

      // Keep local preview path
      setState(() {
        _selfiePath = pickedFile.path;
      });

      // Upload to Supabase Storage (attendance-selfies)
      final pegawaiId = AuthState.instance.currentUser?.pegawaiId ?? '';
      if (pegawaiId.isEmpty) {
        setState(() => _selfieStatus = _DetectionStatus.error);
        _showSnackbar('Gagal mengunggah foto: pegawai tidak ditemukan', isError: true);
        return;
      }

      try {
        final file = File(pickedFile.path);
        final remotePath = await ProfileRemoteDataSource().uploadAttendanceSelfie(
          pegawaiId: pegawaiId,
          imageFile: file,
        );
        if (!mounted) return;
        setState(() {
          _uploadedSelfiePath = remotePath;
          _selfieStatus = _DetectionStatus.success;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _selfieStatus = _DetectionStatus.error);
        _showSnackbar('Gagal mengunggah foto selfie: $e', isError: true);
      }
    } catch (e) {
      setState(() => _selfieStatus = _DetectionStatus.error);
      _showSnackbar('Gagal mengambil foto selfie: $e', isError: true);
    }
  }

  void _submitCheckIn() async {
    final pegawaiId = AuthState.instance.currentUser?.pegawaiId ?? '';
    try {
      await AttendanceService().checkIn(
        pegawaiId: pegawaiId,
        skemaKerja: 'WFH',
        latitude: _latitude,
        longitude: _longitude,
        fotoSelfie: _uploadedSelfiePath ?? _selfiePath,
        catatan: 'Absen WFH dari Rumah',
      );
      _showSnackbar('Check In WFH Berhasil!');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showSnackbar('Gagal melakukan Check In: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: AppTypography.textTheme.bodyMedium
                ?.copyWith(color: Colors.white, fontSize: 13)),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBanner(
            icon: Icons.home_outlined,
            title: 'Work From Home',
            subtitle:
                'Absensi dilakukan dengan verifikasi lokasi GPS dan foto selfie dari rumah.',
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 1: GPS Location
          _StepCard(
            step: 1,
            title: 'Deteksi Lokasi GPS',
            subtitle:
                'Pastikan GPS aktif. Sistem akan mendeteksi koordinat lokasi kamu saat ini.',
            icon: Icons.location_on_outlined,
            status: _locationStatus,
            onAction: _locationStatus == _DetectionStatus.idle ||
                    _locationStatus == _DetectionStatus.error
                ? _detectLocation
                : null,
            actionLabel: 'Deteksi Lokasi',
            successText: _locationText,
            loadingText: 'Mengambil koordinat GPS...',
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 2: Selfie
          _StepCard(
            step: 2,
            title: 'Foto Selfie',
            subtitle:
                'Ambil foto selfie untuk verifikasi kehadiran. Pastikan wajah terlihat jelas.',
            icon: Icons.camera_alt_outlined,
            status: _selfieStatus,
            onAction: _selfieStatus == _DetectionStatus.idle ||
                    _selfieStatus == _DetectionStatus.error
                ? _takeSelfie
                : null,
            actionLabel: 'Ambil Foto Selfie',
            successText: 'Foto selfie berhasil diambil',
            loadingText: 'Memproses foto...',
            accentColor: AppColors.primary,
            previewWidget: _selfieStatus == _DetectionStatus.success
                ? _SelfiePreview(imagePath: _selfiePath)
                : null,
          ),

          const SizedBox(height: AppSpacing.xl),
          AnimatedOpacity(
            opacity: _canSubmit ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canSubmit ? _submitCheckIn : null,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  'Konfirmasi Check In WFH',
                  style: AppTypography.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pill),
                  elevation: _canSubmit ? 4 : 0,
                  shadowColor: AppColors.primary.withAlpha(100),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Widgets lokal WFH
// ─────────────────────────────────────────────────

class _SelfiePreview extends StatelessWidget {
  const _SelfiePreview({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.success.withAlpha(80)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.medium,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (imagePath != null && File(imagePath!).existsSync())
              Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              const Icon(Icons.person_outline,
                  size: 48, color: AppColors.textDisabled),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  'Terverifikasi',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Shared components (copy dari wfo page untuk kemandirian file)
// ─────────────────────────────────────────────────

enum _DetectionStatus { idle, loading, success, error }

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.4,
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.onAction,
    required this.actionLabel,
    required this.successText,
    required this.loadingText,
    this.accentColor,
    this.previewWidget,
  });

  final int step;
  final String title;
  final String subtitle;
  final IconData icon;
  final _DetectionStatus status;
  final VoidCallback? onAction;
  final String actionLabel;
  final String successText;
  final String loadingText;
  final Color? accentColor;
  final Widget? previewWidget;

  Color get _statusColor {
    switch (status) {
      case _DetectionStatus.success:
        return AppColors.success;
      case _DetectionStatus.error:
        return AppColors.danger;
      case _DetectionStatus.loading:
        return AppColors.warning;
      case _DetectionStatus.idle:
        return AppColors.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppColors.primary;
    final isLoading = status == _DetectionStatus.loading;
    final isSuccess = status == _DetectionStatus.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isSuccess ? AppColors.success.withAlpha(80) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: isSuccess
                ? AppColors.success.withAlpha(20)
                : AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.success : effectiveAccentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isSuccess
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '$step',
                        style: AppTypography.textTheme.labelSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isSuccess ? Icons.check_circle : icon,
                  key: ValueKey(isSuccess),
                  color: _statusColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              subtitle,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading || isSuccess) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm, horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(18),
                borderRadius: AppRadius.medium,
              ),
              child: Row(
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: _statusColor, strokeWidth: 2),
                    )
                  else
                    Icon(Icons.check_circle_outline,
                        color: _statusColor, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isLoading ? loadingText : successText,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ?previewWidget,
            const SizedBox(height: AppSpacing.sm),
          ],
          if (onAction != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(icon, size: 16, color: Colors.white),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium),
                  textStyle: AppTypography.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
