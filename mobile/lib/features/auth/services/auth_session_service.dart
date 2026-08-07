import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/auth_user.dart';

class AuthSessionService {
  static const _loggedInKey = 'auth_is_logged_in';
  static const _usernameKey = 'auth_username';
  static const _roleKey = 'auth_role';
  static const _akunIdKey = 'auth_akun_id';
  static const _pegawaiIdKey = 'auth_pegawai_id';
  static const _namaPegawaiKey = 'auth_nama_pegawai';
  static const _emailKey = 'auth_email';
  static const _jabatanKey = 'auth_jabatan';
  static const _divisiKey = 'auth_divisi';
  static const _fotoProfileKey = 'auth_foto_profile';
  static const _accessTokenKey = 'auth_access_token';

  Future<AuthUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (!isLoggedIn) return null;

    final username = prefs.getString(_usernameKey);
    final role = prefs.getString(_roleKey);
    final akunId = prefs.getString(_akunIdKey);
    final pegawaiId = prefs.getString(_pegawaiIdKey);
    final namaPegawai = prefs.getString(_namaPegawaiKey);
    final email = prefs.getString(_emailKey);
    final jabatan = prefs.getString(_jabatanKey);
    final divisi = prefs.getString(_divisiKey);
    final fotoProfile = prefs.getString(_fotoProfileKey);
    final accessToken = prefs.getString(_accessTokenKey);

    if (username == null || role == null || akunId == null || pegawaiId == null) {
      return null;
    }

    return AuthUser(
      akunId: akunId,
      pegawaiId: pegawaiId,
      username: username,
      role: role,
      namaPegawai: namaPegawai ?? '',
      email: email ?? '',
      jabatan: jabatan ?? '',
      divisi: divisi ?? '',
      fotoProfile: fotoProfile ?? '',
      accessToken: accessToken ?? '',
    );
  }

  Future<void> persistSession(
    AuthUser user, {
    String? accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_roleKey, user.role);
    await prefs.setString(_akunIdKey, user.akunId);
    await prefs.setString(_pegawaiIdKey, user.pegawaiId);
    await prefs.setString(_namaPegawaiKey, user.namaPegawai);
    await prefs.setString(_emailKey, user.email);
    await prefs.setString(_jabatanKey, user.jabatan);
    await prefs.setString(_divisiKey, user.divisi);
    await prefs.setString(_fotoProfileKey, user.fotoProfile);
    final tokenToStore = accessToken ?? user.accessToken;
    if (tokenToStore.isNotEmpty) {
      await prefs.setString(_accessTokenKey, tokenToStore);
    }
  }

  Future<void> persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.isNotEmpty) {
      await prefs.setString(_accessTokenKey, token);
    }
  }

  Future<String?> restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    return token?.isNotEmpty == true ? token : null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_akunIdKey);
    await prefs.remove(_pegawaiIdKey);
    await prefs.remove(_namaPegawaiKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_jabatanKey);
    await prefs.remove(_divisiKey);
    await prefs.remove(_fotoProfileKey);
    await prefs.remove(_accessTokenKey);
  }
}
