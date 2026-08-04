import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_shadow.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  late Timer _timer;
  late String _currentTime;
  final String employeeName = 'Farida';
  final String attendanceStatus = 'Belum Check In';
  final String workType = 'Work From Office (WFO)';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm').format(now);
    setState(() {
      _currentTime = formattedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            _HomeHeader(name: employeeName),
            const SizedBox(height: AppSpacing.xxl),
            AttendanceStatusCard(
              currentTime: _currentTime,
              attendanceStatus: attendanceStatus,
            ),
            const SizedBox(height: AppSpacing.xxl),
            WorkScheduleCard(
              workType: workType,
              startTime: '08:30 WIB',
              endTime: '15:30 WIB',
            ),
            const SizedBox(height: AppSpacing.xxl),
            RecentActivityCard(
              activities: const [
                ActivityRowData(
                  icon: Icons.check_circle_outline,
                  title: 'Check In Berhasil',
                  subtitle: 'Hari ini, 08:25 WIB',
                  statusLabel: 'Berhasil',
                  statusColor: AppColors.success,
                ),
                ActivityRowData(
                  icon: Icons.work_outline,
                  title: 'Pengajuan WFH',
                  subtitle: 'Kemarin, 10:00 WIB',
                  statusLabel: 'Pending',
                  statusColor: AppColors.warning,
                ),
                ActivityRowData(
                  icon: Icons.logout,
                  title: 'Check Out Berhasil',
                  subtitle: 'Kemarin, 15:30 WIB',
                  statusLabel: 'Berhasil',
                  statusColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hai, $name',
                style: AppTypography.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Selamat datang kembali!',
                style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const NotificationButton(),
      ],
    );
  }
}

class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({
    required this.currentTime,
    required this.attendanceStatus,
    super.key,
  });

  final String currentTime;
  final String attendanceStatus;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final maxIllustrationWidth = min(160.0, constraints.maxWidth * 0.36);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Hari Ini',
                        style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const StatusBadge(label: 'Belum Check In', variant: StatusBadgeVariant.warning),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              currentTime,
                              style: AppTypography.textTheme.displaySmall?.copyWith(fontSize: 44, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'WIB',
                            style: AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              attendanceStatus,
                              style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: maxIllustrationWidth,
                  child: AttendanceIllustration(),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          const InfoBanner(
            text: 'Anda Belum Melakukan Check In',
            color: AppColors.danger,
            icon: Icons.error_outline,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum Check In',
                      style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Jangan lupa melakukan check in sebelum jam masuk.',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Flexible(
                fit: FlexFit.loose,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    elevation: 0,
                  ),
                  child: Text('Check In', style: AppTypography.textTheme.labelLarge),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkScheduleCard extends StatelessWidget {
  const WorkScheduleCard({
    required this.workType,
    required this.startTime,
    required this.endTime,
    super.key,
  });

  final String workType;
  final String startTime;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jadwal Hari Ini', style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(workType, style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const ScheduleBadge(label: 'Jadwal Tetap'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: ScheduleItem(
                  title: 'Jam Masuk',
                  time: startTime,
                  icon: Icons.login, 
                  iconColor: AppColors.success,
                  borderColor: const Color.fromRGBO(34, 197, 94, 0.2),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ScheduleItem(
                  title: 'Jam Pulang',
                  time: endTime,
                  icon: Icons.logout,
                  iconColor: AppColors.danger,
                  borderColor: const Color.fromRGBO(239, 68, 68, 0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    required this.activities,
    super.key,
  });

  final List<ActivityRowData> activities;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aktivitas Terbaru',
                  style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Lihat Semua >',
                style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...activities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ActivityItem(data: activity),
              )),
        ],
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  const ActivityItem({required this.data, super.key});

  final ActivityRowData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _withAlpha(data.statusColor, 0.12),
            borderRadius: AppRadius.pill,
          ),
          child: Icon(data.icon, color: data.statusColor, size: 22),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Text(data.subtitle, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        StatusBadge(label: data.statusLabel, variant: data.variant),
      ],
    );
  }
}

class ActivityRowData {
  const ActivityRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;

  StatusBadgeVariant get variant {
    if (statusColor == AppColors.success) return StatusBadgeVariant.success;
    if (statusColor == AppColors.warning) return StatusBadgeVariant.warning;
    if (statusColor == AppColors.danger) return StatusBadgeVariant.danger;
    return StatusBadgeVariant.info;
  }
}

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.notifications_none, color: AppColors.textPrimary, size: 24),
        ),
      ),
    );
  }
}

class PrimaryCard extends StatelessWidget {
  const PrimaryCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        boxShadow: AppShadow.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.variant, super.key});

  final String label;
  final StatusBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = variant == StatusBadgeVariant.success
        ? const Color.fromRGBO(34, 197, 94, 0.12)
        : variant == StatusBadgeVariant.warning
            ? const Color.fromRGBO(245, 158, 11, 0.15)
            : variant == StatusBadgeVariant.danger
                ? const Color.fromRGBO(239, 68, 68, 0.15)
                : const Color.fromRGBO(59, 130, 246, 0.12);

    final textColor = variant == StatusBadgeVariant.success
        ? AppColors.success
        : variant == StatusBadgeVariant.warning
            ? AppColors.warning
            : variant == StatusBadgeVariant.danger
                ? AppColors.danger
                : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pill,
      ),
      child: Text(label, style: AppTypography.textTheme.labelSmall?.copyWith(color: textColor)),
    );
  }
}

enum StatusBadgeVariant { success, warning, danger, info }

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.text,
    required this.color,
    required this.icon,
    super.key,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _withAlpha(color, 0.12),
        borderRadius: AppRadius.medium,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

Color _withAlpha(Color color, double opacity) {
  return color.withAlpha((opacity * 255).round());
}

class ScheduleBadge extends StatelessWidget {
  const ScheduleBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        border: Border.all(color: const Color.fromRGBO(37, 99, 235, 0.25)),
        color: AppColors.surface,
      ),
      child: Text(label, style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.primary)),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    super.key,
  });

  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _withAlpha(iconColor, 0.12),
              borderRadius: AppRadius.pill,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text(time, style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// Bottom navigation is provided by the shared EmployeeScaffold to keep it persistent.

class AttendanceIllustration extends StatelessWidget {
  const AttendanceIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.large,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(37, 99, 235, 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Illustration',
                style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
