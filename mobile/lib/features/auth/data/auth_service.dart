import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _loggedInKey = 'auth_logged_in';
  static const _userEmailKey = 'auth_user_email';
  static const _seedEmail = 'rahmaattaya@gmail.com';
  static const _seedPassword = '06062000';
  static const _seedNip = '06062000';

  Future<bool> login({required String identifier, required String password}) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final isValidCredentials =
        (normalizedIdentifier == _seedEmail || normalizedIdentifier == _seedNip) &&
        normalizedPassword == _seedPassword;

    if (!isValidCredentials) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userEmailKey, _seedEmail);
    return true;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userEmailKey);
  }
}
