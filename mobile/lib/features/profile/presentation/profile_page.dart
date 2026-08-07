import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../auth/data/auth_service.dart';
import '../../auth/services/auth_state.dart';
import 'edit_profile_sheet.dart';
import 'profile_image_storage.dart';
import 'success_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  String? _errorMessage;
  Map<String, dynamic>? _pegawaiData;

  String _email = '';
  String _phone = '';
  XFile? _pickedImage;
  String? _savedImagePath;



  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    debugPrint("===== FETCH PROFILE =====");

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = AuthState.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Sesi login telah berakhir atau tidak ditemukan.';
          });
        }
        return;
      }

      final detail = await AuthService().getPegawaiDetail(
        currentUser.pegawaiId,
      );

      debugPrint("Pegawai ID : ${currentUser.pegawaiId}");
      debugPrint("Data DB    : $detail");

      if (detail != null && mounted) {
        setState(() {
          _pegawaiData = detail;
          _email = detail['email']?.toString() ?? '';
          _phone = detail['no_handphone']?.toString() ?? '';
          _savedImagePath = detail['foto_profile']?.toString() ?? '';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mengambil data profil dari server.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Koneksi bermasalah: $e';
        });
      }
    }
  }

  String _mapStatus(String? status) {
    if (status == null || status.isEmpty) return 'Tetap';
    if (status.toLowerCase() == 'aktif') return 'Tetap';
    return status;
  }

  ImageProvider _getProfileImage(String? fotoProfile) {
    if (_pickedImage != null) {
      return FileImage(File(_pickedImage!.path));
    }
    if (_savedImagePath != null && _savedImagePath!.isNotEmpty) {
      if (File(_savedImagePath!).existsSync()) {
        return FileImage(File(_savedImagePath!));
      }
    }
    if (fotoProfile != null && fotoProfile.isNotEmpty) {
      if (fotoProfile.startsWith('http://') ||
          fotoProfile.startsWith('https://')) {
        return NetworkImage(fotoProfile);
      }
      if (File(fotoProfile).existsSync()) {
        return FileImage(File(fotoProfile));
      }
      final url =
          'https://fxovkmcrdeezrotwqjhb.supabase.co/storage/v1/object/public/foto_profile/$fotoProfile';
      return NetworkImage(url);
    }
    return const NetworkImage('https://i.pravatar.cc/300');
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted || storageStatus.isLimited;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    return true;
  }

  Future<void> _pickProfileImage() async {
    if (!mounted) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (pickedFile != null) {
      final currentUser = AuthState.instance.currentUser;
      if (currentUser != null) {
        try {
          final fileName =
              '${currentUser.pegawaiId}_${DateTime.now().millisecondsSinceEpoch}_profile.jpg';
          final savedPath = await ProfileImageStorage()
              .copyProfileImageToAppStorage(File(pickedFile.path), fileName);

          setState(() {
            _pickedImage = pickedFile;
            _savedImagePath = savedPath;
            if (_pegawaiData != null) {
              _pegawaiData!['foto_profile'] = savedPath;
            }
          });

          await AuthService().updatePegawai(currentUser.pegawaiId, {
            'foto_profile': savedPath,
          });

          await AuthState.instance.updateCurrentUserFotoProfile(savedPath);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan foto profil: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthState.instance.currentUser;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D35AB)),
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat data profil...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Pengguna belum masuk.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchProfileData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final namaPegawai =
        _pegawaiData?['nama_pegawai']?.toString() ?? currentUser.namaPegawai;
    final jabatan = _pegawaiData?['jabatan']?.toString() ?? currentUser.jabatan;
    final divisi = _pegawaiData?['divisi']?.toString() ?? currentUser.divisi;
    final headerDivisi = divisi.isNotEmpty ? 'Divisi $divisi' : 'Divisi -';
    final detailDivisi = divisi.isNotEmpty ? '$divisi Division' : '-';
    final nip = _pegawaiData?['nip']?.toString() ?? 'EMP-001';
    final statusKaryawan = _mapStatus(_pegawaiData?['status']?.toString());
    final fotoProfile = _pegawaiData?['foto_profile']?.toString();

    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F9FC,
      ), // Background abu-abu muda lembut
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Text(
                'Profil',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola informasi akun anda',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Card 1: User Brief Info Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Avatar dengan Tombol Edit Pensil (Clickable)
                    Stack(
                      children: [
Material(
  color: Colors.transparent,
  shape: const CircleBorder(),
  clipBehavior: Clip.antiAlias,
  child: Ink.image(
    image: _getProfileImage(fotoProfile),
    fit: BoxFit.cover,
    width: 72,
    height: 72,
    child: InkWell(
      onTap: () async {
        await _pickProfileImage();
      },
    ),
  ),
),
Positioned(
  right: 0,
  bottom: 0,
  child: Material(
    color: Colors.transparent,
    shape: const CircleBorder(),
    clipBehavior: Clip.hardEdge,
    child: InkWell(
      onTap: () async {
        await _pickProfileImage();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(
            0xFF1D35AB,
          ), // Warna biru sesuai gambar
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.edit,
          size: 12,
          color: Colors.white,
        ),
      ),
    ),
  ),
),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Informasi Teks User
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaPegawai,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          jabatan,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          headerDivisi,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Informasi Pegawai
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Section Title & Edit Button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Informasi Pegawai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () async {
                              final result = await showModalBottomSheet<Map<String, String>>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => EditProfileSheet(
                                  currentEmail: _email,
                                  currentPhone: _phone,
                                ),
                              );

<<<<<<< Updated upstream
                              if (result == null || !context.mounted) return;

                              final nextEmail = result['email']!.trim();
                              final nextPhone = result['phone']!.trim();

                              try {
                                final success = await AuthService().updatePegawai(
                                  currentUser.pegawaiId,
                                  {
                                    'email': nextEmail,
                                    'no_handphone': nextPhone,
                                  },
                                );

                                if (!success) {
                                  throw Exception('Gagal memperbarui informasi kontak.');
                                }

                                // Update session setelah database berhasil di-update
                                AuthState.instance.updateCurrentUserEmail(nextEmail);

                                // Refresh data profile dari database
                                await _fetchProfileData();

                                if (!context.mounted) return;

                                await showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const SuccessSheet(
                                    title: 'Berhasil!',
                                    message: 'Informasi kontak berhasil diperbarui.',
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst('Exception: ', ''),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
=======
                              if (result != null && context.mounted) {
                                final nextEmail =
                                    result['email']?.trim().isNotEmpty == true
                                    ? result['email']!
                                    : _email;
                                final nextPhone =
                                    result['phone']?.trim().isNotEmpty == true
                                    ? result['phone']!
                                    : _phone;
                                debugPrint(
                                  'EDIT PROFILE submit pegawaiId=${currentUser.pegawaiId}, email=$nextEmail, phone=$nextPhone',
                                );
                                final success = await AuthService().updatePegawai(
                                  currentUser.pegawaiId,
                                  {
                                    'email': nextEmail,
                                    'no_handphone': nextPhone,
                                  },
                                );

                                if (!success) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Gagal menyimpan perubahan ke database.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                await AuthState.instance.updateCurrentUserEmail(
                                  nextEmail,
                                );
                                await _fetchProfileData();

                                if (!context.mounted) return;
                                await showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const SuccessSheet(
                                    title: 'Berhasil!',
                                    message:
                                        'Informasi kontak berhasil diperbarui.',
                                  ),
                                );
>>>>>>> Stashed changes
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: Color(0xFFD97706),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Detail List
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Nama Lengkap',
                      value: namaPegawai,
                    ),
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'NIP',
                      value: nip,
                    ),
                    _buildInfoRow(
                      icon: Icons.business_center_outlined,
                      label: 'Divisi',
                      value: detailDivisi,
                    ),
                    _buildInfoRow(
                      icon: Icons.work_outline,
                      label: 'Jabatan',
                      value: jabatan,
                    ),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _email,
                    ),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'No. Handphone',
                      value: _phone,
                    ),
                    _buildInfoRow(
                      icon: Icons.assignment_ind_outlined,
                      label: 'Status Karyawan',
                      value: statusKaryawan,
                      isTag: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 3: Informasi Kerja
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.cases_outlined,
                            color: Color(0xFF059669),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Informasi Kerja',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWorkInfoTile(
                            icon: Icons.access_time,
                            iconBgColor: const Color(0xFFD1FAE5),
                            iconColor: const Color(0xFF059669),
                            title: 'Jam Kerja',
                            subtitle: '08.00 - 17.00 WIB',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildWorkInfoTile(
                            icon: Icons.domain,
                            iconBgColor: const Color(0xFFD1FAE5),
                            iconColor: const Color(0xFF059669),
                            title: 'Lokasi Kerja',
                            subtitle: 'Work From Office (WFO)',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Button Log Out
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text(
                          'Apakah Anda yakin ingin keluar dari akun ini?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await AuthState.instance.logout();
                    }
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFFE11D48)),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFE11D48),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE4E6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    minimumSize: const Size(double.infinity, 48),
                    alignment: Alignment.center,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pendukung untuk baris list Informasi Pegawai
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isTag = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: isTag
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.6, color: Colors.grey[200]),
      ],
    );
  }

  // Widget pendukung untuk kotak Informasi Kerja
  Widget _buildWorkInfoTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
