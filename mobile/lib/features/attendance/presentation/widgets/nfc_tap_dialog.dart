import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

/// Pop Up Dialog untuk Tap Kartu NFC absensi WFO sesuai desain UI.
class NfcTapDialog extends StatefulWidget {
  const NfcTapDialog({
    this.isCheckOut = false,
    this.onSuccess,
    super.key,
  });

  /// True jika proses NFC ini untuk Check Out, False jika untuk Check In
  final bool isCheckOut;

  /// Callback yang dipanggil ketika scan/tap kartu NFC berhasil
  final VoidCallback? onSuccess;

  /// Helper statis untuk menampilkan popup NFC
  static Future<void> show(
    BuildContext context, {
    bool isCheckOut = false,
    VoidCallback? onSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => NfcTapDialog(
        isCheckOut: isCheckOut,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<NfcTapDialog> createState() => _NfcTapDialogState();
}

class _NfcTapDialogState extends State<NfcTapDialog> {
  bool _isSuccess = false;

  void _handleTapCard() {
    setState(() => _isSuccess = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
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
                  child: Text(
                    'X',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tap area container (interactive simulation)
            GestureDetector(
              onTap: _isSuccess ? null : _handleTapCard,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isSuccess) ...[
                    // Large Golden/Mustard Triangle Warning Icon
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 110,
                      color: Color(0xFFB58E29), // Golden amber color from screenshot
                    ),
                    const SizedBox(height: 20),

                    // Main Text
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
                    Text(
                      '(Ketuk popup untuk simulasi tap kartu NFC)',
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ] else ...[
                    // Success State
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
                      'Kartu Berhasil\nTerdeteksi!',
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
