import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/data/notification_service.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/domain/models/notification_model.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/presentation/widgets/notification_card.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/services/notification_read_service.dart';
import 'package:sip_sistem_absensi_mobile/shared/widgets/empty_state/empty_state.dart';

/// Halaman Notifikasi Pegawai.
///
/// Menampilkan daftar notifikasi yang diambil dari tabel [notifikasi] di Supabase,
/// difilter berdasarkan [pegawai_id] yang sedang login.
///
/// Status baca (biru = belum dibaca, abu = sudah dibaca) disimpan secara
/// persisten menggunakan [NotificationReadService] (SharedPreferences).
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final NotificationReadService _readService = NotificationReadService();

  List<NotificationModel> _notifications = const [];
  Map<String, bool> _readStatuses = const {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Memuat notifikasi dari Supabase dan status baca dari SharedPreferences.
  Future<void> _loadNotifications() async {
    final pegawaiId = AuthState.instance.currentUser?.pegawaiId;
    if (pegawaiId == null || pegawaiId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi pengguna tidak ditemukan.';
      });
      return;
    }

    try {
      final notifications = await _notificationService.fetchNotifications(pegawaiId);
      final ids = notifications.map((n) => n.notifikasiId).toList();
      final readStatuses = await _readService.fetchReadStatuses(ids);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _readStatuses = readStatuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat notifikasi. Periksa koneksi Anda.';
        });
      }
    }
  }

  /// Menandai notifikasi sebagai sudah dibaca saat card di-tap.
  Future<void> _markAsRead(String notifikasiId) async {
    if (_readStatuses[notifikasiId] == true) return; // sudah dibaca, tidak perlu update
    await _readService.markAsRead(notifikasiId);
    if (mounted) {
      setState(() {
        _readStatuses = Map.from(_readStatuses)..[notifikasiId] = true;
      });
    }
  }

  void _showNotificationDetail(NotificationModel notification) {
    _markAsRead(notification.notifikasiId);

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  notification.judul,
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_formatDate(notification.tanggalKirim)} · ${_formatTime(notification.tanggalKirim)}',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Divider(height: 32, thickness: 1, color: AppColors.border),
                Text(
                  notification.isiPesan,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format [DateTime] menjadi "23 Juli 2026".
  String _formatDate(DateTime dt) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
  }

  /// Format [DateTime] menjadi "09:30 WIB".
  String _formatTime(DateTime dt) {
    return '${DateFormat('HH:mm').format(dt)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: const _BackButton(),
        title: Text(
          'Notifikasi Anda',
          style: AppTypography.textTheme.headlineSmall,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return EmptyState(
        title: 'Terjadi Kesalahan',
        subtitle: _errorMessage,
      );
    }

    if (_notifications.isEmpty) {
      return const EmptyState(
        title: 'Belum ada notifikasi',
        subtitle: 'Notifikasi dari admin akan muncul di sini.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      itemCount: _notifications.length + 1, // +1 untuk label "Hari Ini"
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _SectionLabel(label: 'Hari Ini');
        }
        final notification = _notifications[index - 1];
        final isRead = _readStatuses[notification.notifikasiId] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: NotificationCard(
            title: notification.judul,
            message: notification.isiPesan,
            date: _formatDate(notification.tanggalKirim),
            time: _formatTime(notification.tanggalKirim),
            isRead: isRead,
            onTap: () => _showNotificationDetail(notification),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

/// Tombol back dengan icon panah kiri sesuai design Figma.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

/// Label section seperti "Hari Ini".
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
