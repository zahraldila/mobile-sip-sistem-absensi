import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

/// UI Check In mode Work From Office (WFO).
/// Metode: scan NFC + validasi koneksi Wi-Fi perusahaan.
class CheckInWfoPage extends StatefulWidget {
  const CheckInWfoPage({super.key});

  @override
  State<CheckInWfoPage> createState() => _CheckInWfoPageState();
}

class _CheckInWfoPageState extends State<CheckInWfoPage>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late String _currentTime;
  late String _currentDate;

  // Status deteksi koneksi (simulasi)
  _DetectionStatus _wifiStatus = _DetectionStatus.idle;
  _DetectionStatus _nfcStatus = _DetectionStatus.idle;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _canSubmit =>
      _wifiStatus == _DetectionStatus.success &&
      _nfcStatus == _DetectionStatus.success;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    });
  }

  Future<void> _scanWifi() async {
    setState(() => _wifiStatus = _DetectionStatus.loading);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _wifiStatus = _DetectionStatus.success);
  }

  Future<void> _scanNfc() async {
    if (_wifiStatus != _DetectionStatus.success) {
      _showSnackbar('Validasi Wi-Fi terlebih dahulu', isError: true);
      return;
    }
    setState(() => _nfcStatus = _DetectionStatus.loading);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _nfcStatus = _DetectionStatus.success);
  }

  void _submitCheckIn() {
    _showSnackbar('Check In WFO Berhasil!');
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
            icon: Icons.apartment_outlined,
            title: 'Work From Office',
            subtitle: 'Pastikan kamu berada di kantor dan terhubung ke WiFi perusahaan.',
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 1: Wi-Fi
          _StepCard(
            step: 1,
            title: 'Validasi Wi-Fi Perusahaan',
            subtitle: 'Pastikan perangkat terhubung ke jaringan WiFi kantor.',
            icon: Icons.wifi_rounded,
            status: _wifiStatus,
            onAction: _wifiStatus == _DetectionStatus.idle ||
                    _wifiStatus == _DetectionStatus.error
                ? _scanWifi
                : null,
            actionLabel: 'Periksa Koneksi',
            successText: 'Terhubung ke SIP-Office-WiFi',
            loadingText: 'Mendeteksi jaringan...',
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 2: NFC
          _StepCard(
            step: 2,
            title: 'Tap NFC / RFID',
            subtitle: 'Tempelkan kartu atau tag NFC ke mesin absensi.',
            icon: Icons.nfc_rounded,
            status: _nfcStatus,
            onAction: _nfcStatus == _DetectionStatus.idle ||
                    _nfcStatus == _DetectionStatus.error
                ? _scanNfc
                : null,
            actionLabel: 'Mulai Scan NFC',
            successText: 'NFC berhasil terdeteksi',
            loadingText: 'Menunggu tap NFC...',
            pulseController: _pulseController,
            pulseAnimation: _pulseAnimation,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit Button
          AnimatedOpacity(
            opacity: _canSubmit ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canSubmit ? _submitCheckIn : null,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  'Konfirmasi Check In WFO',
                  style: AppTypography.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
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
// Shared Widgets
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
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
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
                child: const Icon(Icons.access_time_rounded,
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
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
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
    this.pulseController,
    this.pulseAnimation,
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
  final AnimationController? pulseController;
  final Animation<double>? pulseAnimation;

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
          color: isSuccess
              ? AppColors.success.withAlpha(80)
              : AppColors.border,
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
              // Step number badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.success : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isSuccess
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '$step',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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
              // Status icon
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
          // Status indicator
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
                        color: _statusColor,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Icon(Icons.check_circle_outline,
                        color: _statusColor, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isLoading ? loadingText : successText,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
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
                  backgroundColor: AppColors.primary,
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
