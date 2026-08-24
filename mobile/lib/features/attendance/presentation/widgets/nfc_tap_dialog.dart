import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/core/services/nfc_service.dart';

/// Pop Up Dialog untuk Tap Kartu NFC absensi WFO dengan validasi terintegrasi.
class NfcTapDialog extends StatefulWidget {
  const NfcTapDialog({
    this.isCheckOut = false,
    this.onValidateAndSubmit,
    this.onSuccess,
    super.key,
  });

  /// True jika proses NFC ini untuk Check Out, False jika untuk Check In
  final bool isCheckOut;

  /// Callback untuk memvalidasi kartu NFC dan memproses presensi.
  /// Mengembalikan null jika berhasil, atau String pesan error jika kartu tidak valid/gagal.
  final Future<String?> Function(String uid)? onValidateAndSubmit;

  /// Callback yang dipanggil ketika scan/tap kartu NFC berhasil diverifikasi
  final ValueChanged<String>? onSuccess;

  /// Helper statis untuk menampilkan popup NFC
  static Future<void> show(
    BuildContext context, {
    bool isCheckOut = false,
    Future<String?> Function(String uid)? onValidateAndSubmit,
    ValueChanged<String>? onSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => NfcTapDialog(
        isCheckOut: isCheckOut,
        onValidateAndSubmit: onValidateAndSubmit,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<NfcTapDialog> createState() => _NfcTapDialogState();
}

class _NfcTapDialogState extends State<NfcTapDialog> {
  final NfcService _nfcService = NfcService();
  bool _isSuccess = false;
  bool _isScanning = true;
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _isValidating = false;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      final uid = await _nfcService.scanCard();
      if (!mounted) return;

      // Jika ada callback validasi ke server
      if (widget.onValidateAndSubmit != null) {
        setState(() {
          _isScanning = false;
          _isValidating = true;
        });

        final errorMsg = await widget.onValidateAndSubmit!(uid);
        if (!mounted) return;

        if (errorMsg != null) {
          setState(() {
            _isValidating = false;
            _errorMessage = errorMsg;
          });
          return;
        }
      }

      // Validasi berhasil 100%
      setState(() {
        _isScanning = false;
        _isValidating = false;
        _isSuccess = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess?.call(uid);
    } on NfcScanException catch (error) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _isValidating = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _isValidating = false;
        _errorMessage = 'Gagal membaca kartu NFC. Silakan coba lagi.';
      });
    }
  }

  @override
  void dispose() {
    _nfcService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top close "X" button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. STATE: VALIDATING TO SERVER
                if (_isValidating) ...[
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Memverifikasi\nKartu NFC...',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Memeriksa kesesuaian kartu dengan akun Anda',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ]
                // 2. STATE: ERROR (KARTU TIDAK SESUAI / GAGAL SCAN)
                else if (_errorMessage != null) ...[
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.danger,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Kartu NFC\nTidak Sesuai',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Tap Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]
                // 3. STATE: SUCCESS (KARTU VALID & CHECK IN/OUT BERHASIL)
                else if (_isSuccess) ...[
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Kartu Berhasil\nTerverifikasi!',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isCheckOut
                        ? 'Check Out WFO Berhasil'
                        : 'Check In WFO Berhasil',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]
                // 4. STATE: INITIAL SCANNING (READY TO TAP)
                else ...[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 100,
                    color: Color(0xFFB58E29), // Golden amber
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Silahkan Tap Kartu\nAnda!',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isScanning)
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
