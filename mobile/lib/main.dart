import 'package:flutter/material.dart';
import 'package:sip_sistem_absensi_mobile/app_router.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_theme.dart';

void main() {
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
