import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

/// Card reusable untuk menampilkan satu item notifikasi pegawai.
///
/// Sesuai design Figma:
/// - Icon hijau (check circle) di kiri
/// - Judul + isi pesan di tengah
/// - Waktu + indicator dot (biru = belum baca, abu = sudah baca) di kanan
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.title,
    required this.message,
    required this.date,
    required this.time,
    required this.isRead,
    required this.onTap,
    super.key,
  });

  final String title;
  final String message;

  /// Format: "23 Juli 2026"
  final String date;

  /// Format: "09:30 WIB"
  final String time;

  /// `false` = dot biru (belum dibaca), `true` = dot abu (sudah dibaca).
  final bool isRead;

  final VoidCallback onTap;

  static Color get _dotUnread => AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppRadius.large,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x260F172A),
              blurRadius: 3,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Icon status (hijau check circle) ---
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // --- Konten tengah ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris atas: judul + waktu + dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Waktu
                      Text(
                        time,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _dotUnread,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Isi pesan
                  Text(
                    message,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Tanggal + pengirim
                  Row(
                    children: [
                      Text(
                        date,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '·',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Admin',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
