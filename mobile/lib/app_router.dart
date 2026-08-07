import 'package:go_router/go_router.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/presentation/login_page.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/attendance_detail_page.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/attendance_home_page.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/check_in_page.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/presentation/check_out_page.dart';
import 'package:sip_sistem_absensi_mobile/features/history/presentation/history_page.dart';
import 'package:sip_sistem_absensi_mobile/features/notification/presentation/notification_page.dart';
import 'package:sip_sistem_absensi_mobile/features/profile/presentation/profile_page.dart';
import 'package:sip_sistem_absensi_mobile/features/submission/presentation/submission_page.dart';
import 'package:sip_sistem_absensi_mobile/shared/layout/employee_scaffold.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: AuthState.instance,
    redirect: (context, state) {
      final authState = AuthState.instance;
      final isLoggingIn = state.uri.path == '/login';

      if (!authState.isInitialized) {
        return null;
      }

      if (!authState.isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return authState.redirectLocation;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => EmployeeScaffold(body: child, currentLocation: state.toString()),
        routes: [
          GoRoute(path: '/attendance', builder: (context, state) => const AttendanceHomePage()),
          GoRoute(path: '/submission', builder: (context, state) => const SubmissionPage()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ],
      ),
      GoRoute(path: '/attendance/check-in', builder: (context, state) => const CheckInPage()),
      GoRoute(path: '/attendance/check-out', builder: (context, state) => const CheckOutPage()),
      GoRoute(path: '/attendance/detail', builder: (context, state) => const AttendanceDetailPage()),
      GoRoute(path: '/history', builder: (context, state) => const HistoryPage()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationPage()),
      // GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardPage()),
    ],
  );
}

