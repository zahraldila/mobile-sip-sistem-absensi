import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sip_sistem_absensi_mobile/app_router.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_theme.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await AuthState.instance.initialize();
  runApp(const SipSistemAbsensiApp());
}

class SipSistemAbsensiApp extends StatelessWidget {
  const SipSistemAbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SIP Sistem Absensi',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
