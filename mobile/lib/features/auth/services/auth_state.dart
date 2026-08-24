import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../data/auth_service.dart';
import '../domain/entities/auth_user.dart';
import 'auth_session_service.dart';
import 'package:sip_sistem_absensi_mobile/core/services/audit_log_service.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/services/activity_service.dart';

class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  final AuthService _authService = AuthService();
  final AuthSessionService _sessionService = AuthSessionService();
  AuthUser? _currentUser;
  bool _initialized = false;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _initialized;

  String get redirectLocation => '/attendance';

  Future<void> initialize() async {
    _currentUser = await _sessionService.restoreSession();
    _initialized = true;
    if (_currentUser != null) {
      try {
        await supabase.Supabase.instance.client.auth.getSession();
      } catch (_) {
        // Ignore refresh failures; app can still use restored token if available.
      }
    }
    notifyListeners();
  }

  String? get lastErrorMessage => _authService.lastErrorMessage;

  Future<bool> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final user = await _authService.login(identifier: identifier, password: password);
    if (user == null) {
      return false;
    }

    _currentUser = user;
    if (rememberMe) {
      await _sessionService.persistSession(
        user,
        accessToken: user.accessToken,
      );
    } else {
      await _sessionService.persistToken(user.accessToken);
    }

    final namaPegawai = user.namaPegawai.isNotEmpty ? user.namaPegawai : user.username;
    await ActivityService.instance.recordAuditActivity('$namaPegawai melakukan Login');
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    // Catat ke audit_log sebelum _currentUser di-clear
    final aktivitas = await AuditLogService.instance.log('Logout');
    if (aktivitas != null) {
      await ActivityService.instance.recordAuditActivity(aktivitas);
    }
    _currentUser = null;
    ActivityService.instance.clear();
    await _sessionService.clearSession();
    notifyListeners();
  }

  Future<void> updateCurrentUserEmail(String newEmail) async {
    if (_currentUser != null) {
      _currentUser = AuthUser(
        akunId: _currentUser!.akunId,
        pegawaiId: _currentUser!.pegawaiId,
        username: _currentUser!.username,
        role: _currentUser!.role,
        namaPegawai: _currentUser!.namaPegawai,
        email: newEmail,
        jabatan: _currentUser!.jabatan,
        divisi: _currentUser!.divisi,
        fotoProfile: _currentUser!.fotoProfile,
        accessToken: _currentUser!.accessToken,
      );
      await _sessionService.persistSession(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> updateCurrentUserFotoProfile(String newFotoProfile) async {
    if (_currentUser != null) {
      _currentUser = AuthUser(
        akunId: _currentUser!.akunId,
        pegawaiId: _currentUser!.pegawaiId,
        username: _currentUser!.username,
        role: _currentUser!.role,
        namaPegawai: _currentUser!.namaPegawai,
        email: _currentUser!.email,
        jabatan: _currentUser!.jabatan,
        divisi: _currentUser!.divisi,
        fotoProfile: newFotoProfile,
        accessToken: _currentUser!.accessToken,
      );
      await _sessionService.persistSession(_currentUser!);
      notifyListeners();
    }
  }
}

