import 'package:get_it/get_it.dart';
import '../data/datasources/attendance_validation_remote_datasource.dart';
import '../data/datasources/gps_local_datasource.dart';
import '../data/datasources/wifi_local_datasource.dart';
import '../data/repositories/attendance_validation_repository_impl.dart';
import '../domain/repositories/attendance_validation_repository.dart';
import '../domain/strategies/distance_validator_strategy.dart';
import '../domain/strategies/gps_validator_strategy.dart';
import '../domain/strategies/permission_validator_strategy.dart';
import '../domain/strategies/wifi_validator_strategy.dart';
import '../domain/usecases/calculate_distance_usecase.dart';
import '../domain/usecases/check_gps_status_usecase.dart';
import '../domain/usecases/check_location_permission_usecase.dart';
import '../domain/usecases/check_wifi_status_usecase.dart';
import '../domain/usecases/submit_validation_log_usecase.dart';
import '../domain/usecases/validate_attendance_usecase.dart';
import '../presentation/cubit/attendance_validation_cubit.dart';
import '../services/distance_calculator_service.dart';
import '../services/gps_service.dart';
import '../services/permission_service.dart';
import '../services/wifi_service.dart';

Future<void> initAttendanceValidationDependencies(GetIt sl) async {
  // 1. Services
  sl.registerLazySingleton<PermissionService>(() => PermissionServiceImpl());
  sl.registerLazySingleton<GpsService>(() => GpsServiceImpl());
  sl.registerLazySingleton<DistanceCalculatorService>(
      () => DistanceCalculatorServiceImpl());
  sl.registerLazySingleton<WifiService>(() => WifiServiceImpl());

  // 2. Data Sources
  sl.registerLazySingleton<GpsLocalDataSource>(
      () => GpsLocalDataSourceImpl(gpsService: sl()));
  sl.registerLazySingleton<WifiLocalDataSource>(
      () => WifiLocalDataSourceImpl(wifiService: sl()));
  sl.registerLazySingleton<AttendanceValidationRemoteDataSource>(
      () => AttendanceValidationRemoteDataSourceImpl());

  // 3. Strategies
  sl.registerLazySingleton<PermissionValidatorStrategy>(
      () => PermissionValidatorStrategy(permissionService: sl()));
  sl.registerLazySingleton<GpsValidatorStrategy>(
      () => GpsValidatorStrategy(gpsService: sl()));
  sl.registerLazySingleton<DistanceValidatorStrategy>(
      () => DistanceValidatorStrategy(distanceCalculatorService: sl()));
  sl.registerLazySingleton<WifiValidatorStrategy>(
      () => WifiValidatorStrategy(wifiService: sl()));

  // 4. Repository
  sl.registerLazySingleton<AttendanceValidationRepository>(
    () => AttendanceValidationRepositoryImpl(
      remoteDataSource: sl(),
      permissionStrategy: sl(),
      gpsStrategy: sl(),
      distanceStrategy: sl(),
      wifiStrategy: sl(),
    ),
  );

  // 5. Use Cases
  sl.registerLazySingleton(() => ValidateAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => CheckGpsStatusUseCase(sl()));
  sl.registerLazySingleton(() => CheckLocationPermissionUseCase(sl()));
  sl.registerLazySingleton(() => CheckWifiStatusUseCase(sl()));
  sl.registerLazySingleton(() => CalculateDistanceUseCase(sl()));
  sl.registerLazySingleton(() => SubmitValidationLogUseCase(sl()));

  // 6. Presentation / Cubit
  sl.registerFactory(
    () => AttendanceValidationCubit(
      validateAttendanceUseCase: sl(),
      permissionService: sl(),
      gpsService: sl(),
    ),
  );
}
