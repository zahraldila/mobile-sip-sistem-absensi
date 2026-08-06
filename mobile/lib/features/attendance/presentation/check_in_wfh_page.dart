import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

/// UI Check In mode Work From Home (WFH).
/// Metode: GPS/Lokasi + Selfie kamera.
class CheckInWfhPage extends StatefulWidget {
  const CheckInWfhPage({super.key});

  @override
  State<CheckInWfhPage> createState() => _CheckInWfhPageState();
}

class _CheckInWfhPageState extends State<CheckInWfhPage> {
  late Timer _timer;
  late String _currentTime;
  late String _currentDate;

  _DetectionStatus _locationStatus = _DetectionStatus.idle;
  _DetectionStatus _selfieStatus = _DetectionStatus.idle;
  String _locationText = '';

  bool get _canSubmit =>
      _locationStatus == _DetectionStatus.success &&
      _selfieStatus == _DetectionStatus.success;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    });
  }

  Future<void> _detectLocation() async {
    setState(() => _locationStatus = _DetectionStatus.loading);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _locationStatus = _DetectionStatus.success;
      _locationText = 'Jl. Sudirman No. 12, Jakarta Pusat';
    });
  }

  Future<void> _takeSelfie() async {
    if (_locationStatus != _DetectionStatus.success) {
      _showSnackbar('Deteksi lokasi terlebih dahulu', isError: true);
      return;
    }
    setState(() => _selfieStatus = _DetectionStatus.loading);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _selfieStatus = _DetectionStatus.success);
  }

  void _submitCheckIn() {
    _showSnackbar('Check In WFH Berhasil!');
    Navigator.of(context).pop(true);
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _TimeCard(time: _currentTime, date: _currentDate),
          const SizedBox(height: AppSpacing.md),
          _InfoBanner(
            icon: Icons.home_outlined,
            title: 'Work From Home',
            subtitle:
                'Absensi dilakukan dengan verifikasi lokasi GPS dan foto selfie dari rumah.',
            color: const Color(0xFF7C3AED),
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
            accentColor: const Color(0xFF7C3AED),
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
            accentColor: const Color(0xFF7C3AED),
            previewWidget: _selfieStatus == _DetectionStatus.success
                ? _SelfiePreview()
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
                  backgroundColor: const Color(0xFF7C3AED),
                  disabledBackgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pill),
                  elevation: _canSubmit ? 4 : 0,
                  shadowColor: const Color(0xFF7C3AED).withAlpha(100),
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

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.time, required this.date});
  final String time;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waktu Sekarang',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 40,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'WIB',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_outlined,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                date,
                textAlign: TextAlign.right,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    this.accentColor = AppColors.primary,
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
  final Color accentColor;
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
                  color: isSuccess ? AppColors.success : accentColor,
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
