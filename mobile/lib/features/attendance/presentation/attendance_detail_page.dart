import 'package:flutter/material.dart';

class AttendanceDetailPage extends StatelessWidget {
  const AttendanceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Absensi')),
      body: const Center(child: Text('Detail kehadiran harian, lokasi, dan bukti selfie.')),
    );
  }
}
