import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';

class CustomFab extends StatelessWidget {
  const CustomFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor = AppColors.primary,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      elevation: 8,
      child: icon,
    );
  }
}
