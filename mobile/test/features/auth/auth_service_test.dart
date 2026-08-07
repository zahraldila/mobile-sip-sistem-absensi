import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/data/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('login accepts seeded email and password', () async {
    final authService = AuthService();

    final loggedIn = await authService.login(
      identifier: 'rahmaattaya@gmail.com',
      password: '06062000',
    );

    expect(loggedIn, isTrue);
    expect(await authService.isLoggedIn(), isTrue);
  });

  test('login rejects wrong credentials', () async {
    final authService = AuthService();

    final loggedIn = await authService.login(
      identifier: 'rahmaattaya@gmail.com',
      password: 'wrong-password',
    );

    expect(loggedIn, isFalse);
  });
}
