import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/status_badge.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/domain/entities/pengajuan.dart';
import 'package:sip_sistem_absensi_mobile/shared/widgets/cards/primary_card.dart';

class PengajuanDetailSheet extends StatelessWidget {
  const PengajuanDetailSheet({super.key, required this.pengajuan});

  final Pengajuan pengajuan;

  String get _subtitle {
    final createdAt = pengajuan.createdAt;
    if (createdAt != null) {
      return DateFormat('d MMMM yyyy, HH.mm', 'id_ID').format(createdAt) + ' WIB';
    }
    return DateFormat('d MMMM yyyy', 'id_ID').format(pengajuan.tanggal);
  }

  String get _detailMessage {
    final status = pengajuan.status.toLowerCase();
    if (status == 'pending') {
      return 'Menunggu persetujuan dari atasan Anda';
    }
    if (status == 'disetujui') {
      return 'Pengajuan telah disetujui';
    }
    if (status == 'ditolak') {
      return 'Pengajuan ditolak oleh atasan';
    }
    return 'Status pengajuan tidak diketahui';
  }

  IconData get _detailIcon {
    final status = pengajuan.status.toLowerCase();
    if (status == 'pending') return Icons.hourglass_top;
    if (status == 'disetujui') return Icons.check_circle_outline;
    if (status == 'ditolak') return Icons.cancel_outlined;
    return Icons.info_outline;
  }

  Color get _detailColor {
    final status = pengajuan.status.toLowerCase();
    if (status == 'pending') return AppColors.warning;
    if (status == 'disetujui') return AppColors.success;
    if (status == 'ditolak') return AppColors.danger;
    return AppColors.textPrimary;
  }

  String get _tanggalPengajuan {
    return DateFormat('d MMMM yyyy', 'id_ID').format(pengajuan.tanggal);
  }

  String get _lokasiKerja {
    final lower = pengajuan.jenis.toLowerCase();
    if (lower.contains('wfh')) return 'Work From Home (WFH)';
    if (lower.contains('wfc')) return 'Work From Client (WFC)';
    if (lower.contains('izin')) return 'Kantor';
    return 'Kantor';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pengajuan ${pengajuan.jenis}',
                          style: AppTypography.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: pengajuan.status,
                        type: _badgeTypeFromStatus(pengajuan.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diajukan pada $_subtitle',
                    style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _detailColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _detailColor.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_detailIcon, color: _detailColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _detailMessage,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Informasi Pengajuan', style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _DetailInfoCard(
                    icon: Icons.calendar_month,
                    title: 'Tanggal Pengajuan',
                    subtitle: _tanggalPengajuan,
                  ),
                  const SizedBox(height: 12),
                  _DetailInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Lokasi Kerja',
                    subtitle: _lokasiKerja,
                  ),
                  const SizedBox(height: 12),
                  _DetailInfoCard(
                    icon: Icons.description_outlined,
                    title: 'Alasan/Keterangan',
                    subtitle: pengajuan.keterangan?.trim().isNotEmpty == true ? pengajuan.keterangan! : 'Tidak ada keterangan.',
                  ),
                  const SizedBox(height: 20),
                  Text('Lampiran', style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (pengajuan.lampiran != null && pengajuan.lampiran!.trim().isNotEmpty) ...[
                    _AttachmentCard(fileName: pengajuan.lampiran!),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('Tidak ada lampiran.', style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Tutup', style: AppTypography.textTheme.labelLarge?.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  StatusBadgeType _badgeTypeFromStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'pending') return StatusBadgeType.warning;
    if (normalized == 'disetujui') return StatusBadgeType.success;
    if (normalized == 'ditolak') return StatusBadgeType.danger;
    return StatusBadgeType.info;
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName, style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('File lampiran', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () {
                // action placeholder: implement if a file viewer/download exists
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Text('Unduh File', style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
