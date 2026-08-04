import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/attendance',
    routes: [
      GoRoute(path: '/attendance', builder: (context, state) => const PlaceholderPage(title: 'Beranda')),
      GoRoute(path: '/submission', builder: (context, state) => const PlaceholderPage(title: 'Pengajuan')),
      GoRoute(path: '/profile', builder: (context, state) => const PlaceholderPage(title: 'Profil')),
      GoRoute(path: '/history', builder: (context, state) => const PlaceholderPage(title: 'Riwayat')),
      GoRoute(path: '/notifications', builder: (context, state) => const PlaceholderPage(title: 'Notifikasi')),
      GoRoute(path: '/attendance/detail', builder: (context, state) => const PlaceholderPage(title: 'Detail Absensi')),
    ],
  );
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Placeholder: $title')),
    );
  }
}
