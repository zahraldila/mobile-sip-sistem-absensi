import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class DialogConfirmation extends StatelessWidget {
  const DialogConfirmation({
    required this.title,
    required this.message,
    required this.onConfirm,
    this.onCancel,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: AppTypography.textTheme.titleLarge),
      content: Text(message, style: AppTypography.textTheme.bodyMedium),
      actions: [
        TextButton(onPressed: onCancel ?? () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: onConfirm, child: const Text('Konfirmasi')),
      ],
    );
  }
}
