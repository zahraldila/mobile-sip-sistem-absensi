import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileSheet extends StatefulWidget {
  final String currentEmail;
  final String currentPhone;

  const EditProfileSheet({
    super.key,
    required this.currentEmail,
    required this.currentPhone,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validateInput() {
    bool isValid = true;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _emailError = null;
      _phoneError = null;
    });

    // Validasi Email
    if (email.isEmpty) {
      _emailError = 'Email wajib diisi';
      isValid = false;
    } else {
      final emailRegex = RegExp(
        r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
      );

      if (!emailRegex.hasMatch(email)) {
        _emailError = 'Format email tidak valid';
        isValid = false;
      }
    }

    // Validasi Nomor HP
    if (phone.isEmpty) {
      _phoneError = 'Nomor handphone wajib diisi';
      isValid = false;
    } else {
      final phoneRegex = RegExp(r'^[0-9]{10,15}$');

      if (!phoneRegex.hasMatch(phone)) {
        _phoneError =
            'Nomor handphone hanya boleh angka (10-15 digit)';
        isValid = false;
      }
    }

    if (!isValid) {
      setState(() {});
    }

    return isValid;
  }

  void _save() {
    if (!_validateInput()) return;

    Navigator.of(context).pop(<String, String>{
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Kelola Kontak',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Perbarui email dan nomor telepon Anda.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: _emailError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'No. Handphone',
                prefixIcon: const Icon(Icons.phone_outlined),
                errorText: _phoneError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}