import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class PrimaryBottomNavigation extends StatelessWidget {
  const PrimaryBottomNavigation({
    required this.selectedIndex,
    required this.onTap,
    this.items = const [],
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final navItems = items.isNotEmpty
        ? items
        : const [
            BottomNavigationItem(label: 'Beranda', icon: Icons.home_outlined),
            BottomNavigationItem(label: 'Pengajuan', icon: Icons.assignment_outlined),
            BottomNavigationItem(label: 'Profil', icon: Icons.person_outline),
          ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final active = index == selectedIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: AppRadius.pill,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: active ? AppColors.primary : AppColors.textSecondary, size: 24),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.label,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: active ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavigationItem {
  const BottomNavigationItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
