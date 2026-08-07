import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_radius.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    this.label,
    this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? label;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  String? _selectedLabel() {
    final selected = items.firstWhere(
      (item) => item.value == value,
      orElse: () => DropdownMenuItem<T>(value: null, child: const SizedBox()),
    );
    if (selected.child is Text) {
      return (selected.child as Text).data;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _selectedLabel();
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (fieldState) {
        return PopupMenuButton<T>(
          position: PopupMenuPosition.under,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
          onSelected: (selectedValue) {
            fieldState.didChange(selectedValue);
            onChanged(selectedValue);
          },
          itemBuilder: (context) {
            return items.map((item) {
              final isSelected = item.value == value;
              final itemText = item.child is Text ? (item.child as Text).data ?? '' : '';
              return PopupMenuItem<T>(
                value: item.value,
                padding: EdgeInsets.zero,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    itemText,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList();
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.border)),
              errorText: fieldState.errorText,
              hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textDisabled),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? hint ?? '',
                    style: selectedLabel != null
                        ? AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary)
                        : AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.textDisabled),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    this.label,
    this.value,
    this.hint,
    this.onTap,
    this.validator,
    required this.action,
  });

  final String? label;
  final String? value;
  final String? hint;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.medium,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.border)),
              ),
              child: Text(
                value ?? '',
                style: AppTypography.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        action,
      ],
    );
  }
}

class AppUploadField extends StatelessWidget {
  const AppUploadField({
    super.key,
    this.label,
    this.fileName,
    this.hint,
    required this.onTap,
  });

  final String? label;
  final String? fileName;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.medium,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_file, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fileName ?? hint ?? 'Pilih file',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(color: fileName == null ? AppColors.textDisabled : AppColors.textPrimary),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AppMultilineField extends StatelessWidget {
  const AppMultilineField({
    super.key,
    this.controller,
    this.label,
    this.hint,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 5,
      style: AppTypography.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }
}
