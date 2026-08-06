import 'package:flutter/foundation.dart';
import '../data/auth_service.dart';
import '../domain/entities/auth_user.dart';
import 'auth_session_service.dart';

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
    notifyListeners();
  }

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
      await _sessionService.persistSession(user);
    } else {
      await _sessionService.clearSession();
    }
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _sessionService.clearSession();
    notifyListeners();
  }

  void updateCurrentUserEmail(String newEmail) {
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
      );
      _sessionService.persistSession(_currentUser!);
      notifyListeners();
    }
  }

  void updateCurrentUserFotoProfile(String newFotoProfile) {
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
      );
      _sessionService.persistSession(_currentUser!);
      notifyListeners();
    }
  }
}

