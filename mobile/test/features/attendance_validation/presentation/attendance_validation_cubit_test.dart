import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/entities/validation_config.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/entities/validation_failure.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/entities/validation_result.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/usecases/validate_attendance_usecase.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/presentation/cubit/attendance_validation_cubit.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/presentation/cubit/attendance_validation_state.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/services/gps_service.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/services/permission_service.dart';

class MockValidateAttendanceUseCase extends Mock
    implements ValidateAttendanceUseCase {}

class MockPermissionService extends Mock implements PermissionService {}

class MockGpsService extends Mock implements GpsService {}

class FakeValidationConfig extends Fake implements ValidationConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeValidationConfig());
  });

  late MockValidateAttendanceUseCase mockUseCase;
  late MockPermissionService mockPermissionService;
  late MockGpsService mockGpsService;
  late AttendanceValidationCubit cubit;

  setUp(() {
    mockUseCase = MockValidateAttendanceUseCase();
    mockPermissionService = MockPermissionService();
    mockGpsService = MockGpsService();

    cubit = AttendanceValidationCubit(
      validateAttendanceUseCase: mockUseCase,
      permissionService: mockPermissionService,
      gpsService: mockGpsService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('AttendanceValidationCubit', () {
    test('Initial state is AttendanceValidationInitial', () {
      expect(cubit.state, isA<AttendanceValidationInitial>());
    });

    test('runValidation emits InProgress then Success when validation succeeds', () async {
      final successResult = ValidationResult.success(
        latitude: -6.208800,
        longitude: 106.845600,
        accuracy: 10.0,
        distance: 15.0,
        ssid: 'SIP-Office-WiFi',
        timestamp: DateTime.now(),
      );

      when(() => mockUseCase.execute(config: any(named: 'config')))
          .thenAnswer((_) async => successResult);

      final expectedStates = [
        isA<AttendanceValidationInProgress>(),
        isA<AttendanceValidationSuccess>().having(
          (s) => s.result.isValid,
          'isValid',
          isTrue,
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.runValidation();
    });

    test('runValidation emits InProgress then FailureState when GPS is disabled', () async {
      final failureResult = ValidationResult.failed(
        failure: const GpsDisabledFailure(),
        timestamp: DateTime.now(),
      );

      when(() => mockUseCase.execute(config: any(named: 'config')))
          .thenAnswer((_) async => failureResult);

      final expectedStates = [
        isA<AttendanceValidationInProgress>(),
        isA<AttendanceValidationFailureState>().having(
          (s) => s.directActionType,
          'directActionType',
          'enable_gps',
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.runValidation();
    });

    test('executeAction open_settings delegates to permissionService', () async {
      when(() => mockPermissionService.openAppSettingsPage())
          .thenAnswer((_) async => true);

      await cubit.executeAction('open_settings');

      verify(() => mockPermissionService.openAppSettingsPage()).called(1);
    });

    test('reset() emits AttendanceValidationInitial', () {
      cubit.reset();
      expect(cubit.state, isA<AttendanceValidationInitial>());
    });
  });
}
