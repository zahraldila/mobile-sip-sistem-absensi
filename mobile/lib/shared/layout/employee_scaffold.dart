import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/shared/layout/bottom_navigation.dart';

class EmployeeScaffold extends StatelessWidget {
  const EmployeeScaffold({
    required this.body,
    this.title,
    this.floatingActionButton,
    this.currentLocation,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.useSafeArea = true,
    super.key,
  });

  final Widget body;
  final String? title;
  final String? currentLocation;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final bool useSafeArea;

  int _routeToIndex(String location) {
    if (location.startsWith('/submission')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0; // default to attendance/home
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/attendance');
        break;
      case 1:
        GoRouter.of(context).go('/submission');
        break;
      case 2:
        GoRouter.of(context).go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: body,
    );

    final location = currentLocation ?? '/attendance';
    final selectedIndex = _routeToIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: PrimaryBottomNavigation(
        selectedIndex: selectedIndex,
        onTap: (i) => _onTap(context, i),
      ),
      body: useSafeArea ? SafeArea(child: content) : content,
    );
  }
}
