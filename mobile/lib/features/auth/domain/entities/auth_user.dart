class AuthUser {
  final String akunId;
  final String pegawaiId;
  final String username;
  final String role;
  final String namaPegawai;
  final String email;
  final String jabatan;
  final String divisi;
  final String fotoProfile;

  const AuthUser({
    required this.akunId,
    required this.pegawaiId,
    required this.username,
    required this.role,
    required this.namaPegawai,
    required this.email,
    required this.jabatan,
    required this.divisi,
    required this.fotoProfile,
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    final pegawai = map['pegawai'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return AuthUser(
      akunId: map['akun_id']?.toString() ?? '',
      pegawaiId: map['pegawai_id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      namaPegawai: pegawai['nama_pegawai']?.toString() ?? '',
      email: pegawai['email']?.toString() ?? '',
      jabatan: pegawai['jabatan']?.toString() ?? '',
      divisi: pegawai['divisi']?.toString() ?? '',
      fotoProfile: pegawai['foto_profile']?.toString() ?? '',
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        akunId: json['akun_id'] ?? '',
        pegawaiId: json['pegawai_id'] ?? '',
        username: json['username'] ?? '',
        role: json['role'] ?? '',
        namaPegawai: json['nama_pegawai'] ?? '',
        email: json['email'] ?? '',
        jabatan: json['jabatan'] ?? '',
        divisi: json['divisi'] ?? '',
        fotoProfile: json['foto_profile'] ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'akun_id': akunId,
      'pegawai_id': pegawaiId,
      'username': username,
      'role': role,
      'nama_pegawai': namaPegawai,
      'email': email,
      'jabatan': jabatan,
      'divisi': divisi,
      'foto_profile': fotoProfile,
    };
  }
}
