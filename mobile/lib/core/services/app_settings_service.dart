import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_sistem_absensi_mobile/core/config/supabase_config.dart';

/// Service terpusat untuk mengelola branding dan warna dinamis aplikasi
/// yang ditarik dari tabel [settings] di database Supabase.
class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const String _prefPrimaryColorKey = 'app_setting_primary_color';
  static const String _prefCompanyLogoKey = 'app_setting_company_logo';
  static const String _prefCompanyNameKey = 'app_setting_company_name';

  static const Color defaultPrimaryColor = Color(0xFF2563EB);
  static const String defaultCompanyLogo = 'assets/images/logo awal.png';
  static const String defaultCompanyName = 'PT Selada Indonesia Produktif';

  Color _primaryColor = defaultPrimaryColor;
  String _companyLogo = defaultCompanyLogo;
  String _companyName = defaultCompanyName;
  bool _isInitialized = false;

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _primaryColor.withValues(alpha: 0.85);
  Color get navActiveColor => _primaryColor;
  String get companyLogo => _companyLogo;
  String get companyName => _companyName;
  bool get isInitialized => _isInitialized;

  /// Inisialisasi awal: memuat dari cache lokal (SharedPreferences) lalu memperbarui dari database Supabase
  Future<void> initialize() async {
    await _loadFromLocalCache();
    await fetchSettings();
    _isInitialized = true;
    notifyListeners();
  }

  /// Memuat konfigurasi yang tersimpan di cache lokal agar langsung aktif tanpa delay/flicker
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHex = prefs.getString(_prefPrimaryColorKey);
      if (savedHex != null && savedHex.isNotEmpty) {
        _primaryColor = _parseHexColor(savedHex, fallback: defaultPrimaryColor);
      }

      final savedLogo = prefs.getString(_prefCompanyLogoKey);
      if (savedLogo != null && savedLogo.isNotEmpty) {
        _companyLogo = savedLogo;
      }

      final savedName = prefs.getString(_prefCompanyNameKey);
      if (savedName != null && savedName.isNotEmpty) {
        _companyName = savedName;
      }
    } catch (e) {
      debugPrint('[AppSettingsService] Error loading local cache: $e');
    }
  }

  /// Mengambil data setting terbaru dari tabel [settings] Supabase
  Future<void> fetchSettings() async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: SupabaseConfig.url,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dio.get(
        '/rest/v1/settings',
        queryParameters: {
          'select': 'key,value',
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        final prefs = await SharedPreferences.getInstance();
        bool hasChanges = false;

        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final key = map['key']?.toString();
          final value = map['value']?.toString() ?? '';

          if (key == 'primary_color' && value.isNotEmpty) {
            final parsedColor = _parseHexColor(value, fallback: defaultPrimaryColor);
            if (parsedColor.toARGB32() != _primaryColor.toARGB32()) {
              _primaryColor = parsedColor;
              await prefs.setString(_prefPrimaryColorKey, value);
              hasChanges = true;
            }
          } else if (key == 'company_logo' && value.isNotEmpty) {
            if (_companyLogo != value) {
              _companyLogo = value;
              await prefs.setString(_prefCompanyLogoKey, value);
              hasChanges = true;
            }
          } else if (key == 'company_name' && value.isNotEmpty) {
            if (_companyName != value) {
              _companyName = value;
              await prefs.setString(_prefCompanyNameKey, value);
              hasChanges = true;
            }
          }
        }

        if (hasChanges) {
          debugPrint('[AppSettingsService] Settings updated: primaryColor=$_primaryColor, companyName=$_companyName');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AppSettingsService] Error fetching settings from Supabase: $e');
    }
  }

  /// Mengonversi format hex color (misal '#7C3AED' atau '7C3AED') ke objek [Color]
  static Color _parseHexColor(String hexString, {Color fallback = defaultPrimaryColor}) {
    try {
      final buffer = StringBuffer();
      String hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) {
        buffer.write('FF');
        buffer.write(hex);
      } else if (hex.length == 8) {
        buffer.write(hex);
      } else {
        return fallback;
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
