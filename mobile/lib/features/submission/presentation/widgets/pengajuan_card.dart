import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/domain/entities/submission_status.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/presentation/helpers/submission_status_style.dart';
import 'package:sip_sistem_absensi_mobile/shared/widgets/cards/primary_card.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/status_badge.dart';

class PengajuanCard extends StatelessWidget {
  const PengajuanCard({super.key, required this.jenis, required this.tanggal, required this.statusPengajuan, this.onTap});

  final String jenis;
  final DateTime tanggal;
  final String statusPengajuan;
  final VoidCallback? onTap;

  IconData _iconForJenis() {
    final k = jenis.toLowerCase();
    if (k.contains('wfh')) return Icons.home;
    if (k.contains('wfc') || k.contains('wfo')) return Icons.apartment;
    if (k.contains('sakit')) return Icons.medical_information;
    if (k.contains('koreksi')) return Icons.history;
    if (k.contains('izin')) return Icons.document_scanner;
    return Icons.description;
  }

  SubmissionStatusStyle get _statusStyle {
    final status = SubmissionStatusX.fromString(statusPengajuan);
    return SubmissionStatusStyle.fromStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('d MMMM yyyy', 'id_ID').format(tanggal);
    final style = _statusStyle;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: PrimaryCard(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: style.iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(_iconForJenis(), size: 24, color: style.iconColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jenis, style: AppTypography.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(formatted, style: AppTypography.textTheme.bodySmall),
                ],
              ),
            ),
            StatusBadge(label: statusPengajuan, type: style.badgeVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
