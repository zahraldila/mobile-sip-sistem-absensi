import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_shadow.dart';

class PrimaryCard extends StatelessWidget {
  const PrimaryCard({
    required this.child,
    this.color = AppColors.surface,
    super.key,
  });

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.large,
        boxShadow: AppShadow.card,
      ),
      child: child,
    );
  }
}
