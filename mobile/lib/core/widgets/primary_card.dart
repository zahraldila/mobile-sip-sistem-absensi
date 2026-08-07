import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_shadow.dart';

class PrimaryCard extends StatelessWidget {
  const PrimaryCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = AppRadius.large,
    this.elevation = 0,
    this.color = AppColors.surface,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double elevation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: elevation > 0 ? AppShadow.card : null,
      ),
      child: child,
    );
  }
}
