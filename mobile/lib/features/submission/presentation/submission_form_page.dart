import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_spacing.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/app_form_fields.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/app_square_icon_button.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/primary_button.dart';
import 'package:sip_sistem_absensi_mobile/core/widgets/success_dialog.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/data/datasource/pengajuan_remote_data_source.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/data/repository/pengajuan_repository_impl.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/domain/entities/pengajuan_request.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/domain/usecases/create_pengajuan.dart';

class SubmissionFormPage extends StatefulWidget {
  const SubmissionFormPage({super.key});

  @override
  State<SubmissionFormPage> createState() => _SubmissionFormPageState();
}

class _SubmissionFormPageState extends State<SubmissionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  String? _selectedJenis;
  final List<DateTime> _tanggalList = [DateTime.now()];
  String? _selectedFileName;
  bool _isSubmitting = false;

  late final CreatePengajuan _createPengajuan;

  @override
  void initState() {
    super.initState();
    final remote = PengajuanRemoteDataSource();
    final repo = PengajuanRepositoryImpl(remote: remote);
    _createPengajuan = CreatePengajuan(repo);
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  String _formatDisplayDate(DateTime date) => DateFormat('d MMMM yyyy', 'id_ID').format(date);

  Future<void> _pickDate(int index) async {
    final currentDate = _tanggalList[index];
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    if (_tanggalList.any((date) => date.isAtSameMomentAs(picked))) return;

    setState(() {
      _tanggalList[index] = picked;
      _tanggalList.sort();
    });
  }

  void _addDateRow() {
    setState(() {
      _tanggalList.add(DateTime.now().add(Duration(days: _tanggalList.length)));
      _tanggalList.sort();
    });
  }

  void _removeDateRow(int index) {
    if (_tanggalList.length == 1) return;
    setState(() {
      _tanggalList.removeAt(index);
      _tanggalList.sort();
    });
  }

  Future<void> _pickFile() async {
    final typeGroup = XTypeGroup(
      label: 'Dokumen',
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
      mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
    );

    final result = await openFile(acceptedTypeGroups: [typeGroup]);
    if (result == null) return;

    setState(() {
      _selectedFileName = result.name;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final user = AuthState.instance.currentUser;
    if (user == null) {
      _showError('Session tidak ditemukan. Silakan login ulang.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final request = PengajuanRequest(
      pegawaiId: user.pegawaiId,
      jenisPengajuan: _selectedJenis ?? '',
      tanggalPengajuan: List.unmodifiable(_tanggalList),
      lampiran: _selectedFileName,
      keterangan: _keteranganController.text.isEmpty ? null : _keteranganController.text.trim(),
    );

    try {
      await _createPengajuan(request);
      await _showSuccess();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _showError('Gagal mengirim pengajuan. ${_extractErrorMessage(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      return error.response?.data?.toString() ?? error.message ?? 'Unknown error';
    }
    return error.toString();
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gagal', style: AppTypography.textTheme.headlineSmall),
        content: Text(message, style: AppTypography.textTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _showSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: 'Pengajuan Berhasil',
        description: 'Terkirim',
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Pengajuan'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdownField<String>(
                  label: 'Jenis Pengajuan',
                  hint: 'Pilih Jenis Pengajuan',
                  value: _selectedJenis,
                  items: const [
                    DropdownMenuItem(value: 'WFH', child: Text('WFH')),
                    DropdownMenuItem(value: 'WFC', child: Text('WFC')),
                    DropdownMenuItem(value: 'Izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                    DropdownMenuItem(value: 'Koreksi Absensi', child: Text('Koreksi Absensi')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedJenis = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jenis pengajuan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Tanggal', style: AppTypography.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                ..._tanggalList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppDateField(
                      label: null,
                      value: _formatDisplayDate(date),
                      onTap: () => _pickDate(index),
                      validator: (_) {
                        if (_tanggalList.isEmpty) {
                          return 'Minimal harus ada 1 tanggal';
                        }
                        return null;
                      },
                      action: AppSquareIconButton(
                        icon: Icon(index == _tanggalList.length - 1 ? Icons.add : Icons.remove, color: index == _tanggalList.length - 1 ? AppColors.primary : AppColors.danger),
                        onPressed: index == _tanggalList.length - 1 ? _addDateRow : () => _removeDateRow(index),
                        backgroundColor: AppColors.surface,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.lg),
                AppUploadField(
                  label: 'Unggah File',
                  hint: 'Unggah file yang berkaitan',
                  fileName: _selectedFileName,
                  onTap: _pickFile,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppMultilineField(
                  controller: _keteranganController,
                  label: 'Keterangan',
                  hint: 'Tambahkan keterangan jika perlu',
                ),
                const SizedBox(height: AppSpacing.xxxl),
                PrimaryButton(
                  label: _isSubmitting ? 'Mengirim...' : 'Submit',
                  onPressed: _isSubmitting ? () {} : _submit,
                  isExpanded: true,
                  isEnabled: !_isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
