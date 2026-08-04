import 'package:go_router/go_router.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/attendance_detail_page.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/attendance_home_page.dart';
import 'package:sip_sistem_absensi_mobile/features/history/presentation/history_page.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/presentation/notification_page.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/presentation/profile_page.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/presentation/submission_page.dart';
import 'package:sip_sistem_absensi_mobile/shared/layout/employee_scaffold.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/attendance',
    routes: [
      ShellRoute(
        builder: (context, state, child) => EmployeeScaffold(body: child, currentLocation: state.toString()),
        routes: [
          GoRoute(path: '/attendance', builder: (context, state) => const AttendanceHomePage()),
          GoRoute(path: '/submission', builder: (context, state) => const SubmissionPage()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ],
      ),
      // Non-tab routes
      GoRoute(path: '/attendance/detail', builder: (context, state) => const AttendanceDetailPage()),
      GoRoute(path: '/history', builder: (context, state) => const HistoryPage()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationPage()),
    ],
  );
}
