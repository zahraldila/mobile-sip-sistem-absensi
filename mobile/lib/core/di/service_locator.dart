import 'package:get_it/get_it.dart';
import '../../features/attendance_validation/di/attendance_validation_di.dart';

final sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  await initAttendanceValidationDependencies(sl);
}
