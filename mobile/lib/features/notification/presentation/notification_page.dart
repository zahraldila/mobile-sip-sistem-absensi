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
      return const Center(
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
            onTap: () => _markAsRead(notification.notifikasiId),
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
