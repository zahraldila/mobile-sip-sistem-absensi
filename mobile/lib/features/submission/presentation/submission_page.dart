import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/loading_widget.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/error_state.dart' as core_error;
import 'package:sip_sistem_absensi_mobile/core/widgets/empty_state.dart' as core_empty;
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/data/datasource/pengajuan_remote_data_source.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/data/repository/pengajuan_repository_impl.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/domain/usecases/get_pengajuans.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/presentation/widgets/pengajuan_card.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/shared/widgets/cards/primary_card.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';

class SubmissionPage extends StatefulWidget {
  const SubmissionPage({super.key});

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  late final GetPengajuans _getPengajuans;
  late Future<List> _future;
  List _items = [];
  List _allSubmissions = [];
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    final remote = PengajuanRemoteDataSource();
    final repo = PengajuanRepositoryImpl(remote: remote);
    _getPengajuans = GetPengajuans(repo);

    final pegawaiId = AuthState.instance.currentUser?.pegawaiId;
    if (pegawaiId == null || pegawaiId.isEmpty) {
      _future = Future.error('No pegawai id in session');
    } else {
      _future = _getPengajuans(pegawaiId).then((list) {
        _allSubmissions = list;
        _items = List.from(list);
        return list;
      });
    }
  }

  void _applyFilter(String key) {
    setState(() {
      _filter = key;
      if (key == 'Semua') {
        _items = List.from(_allSubmissions);
      } else if (key == 'Pending') {
        _items = _allSubmissions.where((e) => (e.status as String) == 'Pending').toList();
      } else if (key == 'Disetujui') {
        _items = _allSubmissions.where((e) => (e.status as String) == 'Disetujui').toList();
      } else if (key == 'Ditolak') {
        _items = _allSubmissions.where((e) => (e.status as String) == 'Ditolak').toList();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final pegawaiId = AuthState.instance.currentUser?.pegawaiId ?? '';
          final list = await _getPengajuans(pegawaiId);
          setState(() {
            _allSubmissions = list;
            _items = List.from(list);
            _filter = 'Semua';
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 24, bottom: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Pengajuan', style: AppTypography.textTheme.headlineLarge),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Ajukan izin, sakit, WFH dan lainnya dengan mudah.', style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: AppSpacing.xl),

              FutureBuilder<List>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
                  if (snapshot.hasError) return core_error.ErrorState(title: 'Gagal memuat', message: snapshot.error.toString(), actionLabel: 'Coba Lagi', onAction: () { setState(() { initState(); }); });
                  final data = snapshot.data ?? [];
                  // ensure allSubmissions is populated on first load
                  if (_allSubmissions.isEmpty) {
                    _allSubmissions = data;
                    _items = List.from(data);
                  }

                  // statistics always computed from full dataset
                  final total = _allSubmissions.length;
                  final totalIzin = _allSubmissions.where((e) => (e.jenis as String).toLowerCase().contains('izin')).length;
                  final totalSakit = _allSubmissions.where((e) => (e.jenis as String).toLowerCase().contains('sakit')).length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _StatCard(title: 'Total Izin', value: totalIzin.toString())),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(title: 'Total Sakit', value: totalSakit.toString())),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(title: 'Total Pengajuan', value: total.toString())),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _FilterRow(filter: _filter, onFilter: _applyFilter),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (_allSubmissions.isEmpty) ...[
                          const SizedBox(height: 36),
                          const core_empty.EmptyState(title: 'Belum ada pengajuan.', message: ''),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return PengajuanCard(jenis: item.jenis, tanggal: item.tanggal, statusPengajuan: item.status);
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  Color get _backgroundColor {
    if (title.toLowerCase().contains('izin')) return AppColors.success.withAlpha(40);
    if (title.toLowerCase().contains('sakit')) return AppColors.warning.withAlpha(40);
    return AppColors.primary.withAlpha(40);
  }

  Color get _iconColor {
    if (title.toLowerCase().contains('izin')) return AppColors.success;
    if (title.toLowerCase().contains('sakit')) return AppColors.warning;
    return AppColors.primary;
  }

  IconData get _iconData {
    if (title.toLowerCase().contains('izin')) return Icons.assignment;
    if (title.toLowerCase().contains('sakit')) return Icons.medical_information;
    return Icons.task_alt;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: PrimaryCard(
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _iconColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconData, color: _iconColor, size: 20),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTypography.textTheme.headlineSmall?.copyWith(color: _iconColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onFilter});
  final String filter;
  final void Function(String) onFilter;

  _FilterScheme _scheme(String label) {
    switch (label) {
      case 'Pending':
        return _FilterScheme(
          borderColor: AppColors.warning,
          activeFill: AppColors.warning.withAlpha(40),
          activeForeground: AppColors.warning,
          inactiveTextColor: AppColors.warning,
        );
      case 'Disetujui':
        return _FilterScheme(
          borderColor: AppColors.success,
          activeFill: AppColors.success.withAlpha(40),
          activeForeground: AppColors.success,
          inactiveTextColor: AppColors.success,
        );
      case 'Ditolak':
        return _FilterScheme(
          borderColor: AppColors.danger,
          activeFill: AppColors.danger.withAlpha(40),
          activeForeground: AppColors.danger,
          inactiveTextColor: AppColors.danger,
        );
      default:
        return _FilterScheme(
          borderColor: AppColors.primary,
          activeFill: AppColors.primary,
          activeForeground: Colors.white,
          inactiveTextColor: AppColors.primary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = ['Semua', 'Pending', 'Disetujui', 'Ditolak'];
    return Row(
      children: buttons.map((b) {
        final active = b == filter;
        final scheme = _scheme(b);
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: FilledButton(
            onPressed: () => onFilter(b),
            style: FilledButton.styleFrom(
              backgroundColor: active ? scheme.activeFill : AppColors.surface,
              foregroundColor: active ? scheme.activeForeground : scheme.inactiveTextColor,
              side: BorderSide(color: scheme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(b),
          ),
        );
      }).toList(),
    );
  }
}

class _FilterScheme {
  const _FilterScheme({
    required this.borderColor,
    required this.activeFill,
    required this.activeForeground,
    required this.inactiveTextColor,
  });

  final Color borderColor;
  final Color activeFill;
  final Color activeForeground;
  final Color inactiveTextColor;
}

}
