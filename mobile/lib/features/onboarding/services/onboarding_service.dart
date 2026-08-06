import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _key = 'onboarding_completed';

  static Future<bool> isCompleted() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_key) ?? false;
  }

  static Future<void> complete() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_key, true);
  }
}
