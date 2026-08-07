import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';

class AppSquareIconButton extends StatelessWidget {
  const AppSquareIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor = AppColors.surface,
    this.iconColor = AppColors.textPrimary,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.medium,
        child: SizedBox(
          height: 44,
          width: 44,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: iconColor, size: 20),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
