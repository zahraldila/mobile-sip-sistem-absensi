import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: const Offset(0, 10)),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(18.0),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
