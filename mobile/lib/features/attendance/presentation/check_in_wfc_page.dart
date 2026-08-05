import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

/// UI Check In mode Work From Client (WFC).
/// Metode: Input nama/lokasi klien + GPS + Selfie.
class CheckInWfcPage extends StatefulWidget {
  const CheckInWfcPage({super.key});

  @override
  State<CheckInWfcPage> createState() => _CheckInWfcPageState();
}

class _CheckInWfcPageState extends State<CheckInWfcPage> {
  late Timer _timer;
  late String _currentTime;
  late String _currentDate;

  final _clientNameController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _DetectionStatus _locationStatus = _DetectionStatus.idle;
  _DetectionStatus _selfieStatus = _DetectionStatus.idle;
  String _locationText = '';
  bool _clientInfoFilled = false;

  bool get _canSubmit =>
      _clientInfoFilled &&
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
    _clientNameController.dispose();
    _clientAddressController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    });
  }

  void _onClientInfoSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() => _clientInfoFilled = true);
    }
  }

  Future<void> _detectLocation() async {
    if (!_clientInfoFilled) {
      _showSnackbar('Isi informasi klien terlebih dahulu', isError: true);
      return;
    }
    setState(() => _locationStatus = _DetectionStatus.loading);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _locationStatus = _DetectionStatus.success;
      _locationText = 'Lat -6.2146, Lon 106.8451';
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
    _showSnackbar('Check In WFC Berhasil!');
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

  static const _accentColor = Color(0xFFD97706);

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
            icon: Icons.business_center_outlined,
            title: 'Work From Client',
            subtitle:
                'Absensi dilakukan saat bekerja di lokasi klien. Isi data klien, verifikasi lokasi, dan ambil selfie.',
            color: _accentColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 1: Isi informasi klien
          _ClientInfoCard(
            step: 1,
            formKey: _formKey,
            nameController: _clientNameController,
            addressController: _clientAddressController,
            isFilled: _clientInfoFilled,
            onSubmit: _onClientInfoSubmit,
            onEdit: () => setState(() {
              _clientInfoFilled = false;
              _locationStatus = _DetectionStatus.idle;
              _selfieStatus = _DetectionStatus.idle;
            }),
            accentColor: _accentColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 2: GPS
          _StepCard(
            step: 2,
            title: 'Deteksi Lokasi GPS',
            subtitle:
                'Sistem akan mencatat koordinat lokasi klien secara otomatis.',
            icon: Icons.location_on_outlined,
            status: _locationStatus,
            onAction: _locationStatus == _DetectionStatus.idle ||
                    _locationStatus == _DetectionStatus.error
                ? _detectLocation
                : null,
            actionLabel: 'Deteksi Lokasi',
            successText: _locationText,
            loadingText: 'Mengambil koordinat GPS...',
            accentColor: _accentColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 3: Selfie
          _StepCard(
            step: 3,
            title: 'Foto Selfie di Lokasi Klien',
            subtitle:
                'Ambil foto selfie sebagai bukti kehadiran di lokasi klien.',
            icon: Icons.camera_alt_outlined,
            status: _selfieStatus,
            onAction: _selfieStatus == _DetectionStatus.idle ||
                    _selfieStatus == _DetectionStatus.error
                ? _takeSelfie
                : null,
            actionLabel: 'Ambil Foto Selfie',
            successText: 'Foto selfie berhasil diambil',
            loadingText: 'Memproses foto...',
            accentColor: _accentColor,
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
                  'Konfirmasi Check In WFC',
                  style: AppTypography.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  disabledBackgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pill),
                  elevation: _canSubmit ? 4 : 0,
                  shadowColor: _accentColor.withAlpha(100),
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
// Client Info Card (khusus WFC)
// ─────────────────────────────────────────────────

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard({
    required this.step,
    required this.formKey,
    required this.nameController,
    required this.addressController,
    required this.isFilled,
    required this.onSubmit,
    required this.onEdit,
    required this.accentColor,
  });

  final int step;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final bool isFilled;
  final VoidCallback onSubmit;
  final VoidCallback onEdit;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isFilled ? AppColors.success.withAlpha(80) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: isFilled
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
                  color: isFilled ? AppColors.success : accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isFilled
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
                  'Informasi Klien',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isFilled)
                GestureDetector(
                  onTap: onEdit,
                  child: Text(
                    'Ubah',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              'Masukkan nama dan alamat kantor/lokasi klien yang dikunjungi.',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          if (!isFilled) ...[
            const SizedBox(height: AppSpacing.md),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration(
                      label: 'Nama Klien / Perusahaan',
                      hint: 'cth: PT. Maju Jaya',
                      icon: Icons.business_outlined,
                    ),
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nama klien wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: addressController,
                    decoration: _inputDecoration(
                      label: 'Alamat Lokasi Klien',
                      hint: 'cth: Jl. Gatot Subroto No. 5, Jakarta',
                      icon: Icons.location_city_outlined,
                    ),
                    maxLines: 2,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Alamat klien wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                        elevation: 0,
                      ),
                      child: Text(
                        'Simpan Informasi Klien',
                        style: AppTypography.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(18),
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'Klien',
                    value: nameController.text,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Alamat',
                    value: addressController.text,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      hintStyle: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textDisabled,
        fontSize: 11,
      ),
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Shared components
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
          colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withAlpha(80),
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
                child: const Icon(Icons.business_center_outlined,
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
