import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/data/datasources/attendance_validation_remote_datasource.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/data/models/office_rule_model.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/data/models/validation_payload_model.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/data/repositories/attendance_validation_repository_impl.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/entities/office_rule.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/entities/validation_config.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/entities/validation_failure.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/strategies/distance_validator_strategy.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/strategies/gps_validator_strategy.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/strategies/permission_validator_strategy.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/strategies/wifi_validator_strategy.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/domain/usecases/validate_attendance_usecase.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/services/distance_calculator_service.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/services/gps_service.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/services/permission_service.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance_validation/services/wifi_service.dart';

class MockPermissionService extends Mock implements PermissionService {}
class MockGpsService extends Mock implements GpsService {}
class MockWifiService extends Mock implements WifiService {}
class MockRemoteDataSource extends Mock implements AttendanceValidationRemoteDataSource {}
class FakeValidationPayloadModel extends Fake implements ValidationPayloadModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeValidationPayloadModel());
    registerFallbackValue(const Duration(seconds: 10));
  });

  late MockPermissionService mockPermissionService;
  late MockGpsService mockGpsService;
  late MockWifiService mockWifiService;
  late MockRemoteDataSource mockRemoteDataSource;
  late DistanceCalculatorService distanceCalculatorService;

  late PermissionValidatorStrategy permissionStrategy;
  late GpsValidatorStrategy gpsStrategy;
  late DistanceValidatorStrategy distanceStrategy;
  late WifiValidatorStrategy wifiStrategy;

  late AttendanceValidationRepositoryImpl repository;
  late ValidateAttendanceUseCase useCase;

  final defaultOfficeRule = OfficeRule.defaultOffice();

  setUp(() {
    mockPermissionService = MockPermissionService();
    mockGpsService = MockGpsService();
    mockWifiService = MockWifiService();
    mockRemoteDataSource = MockRemoteDataSource();
    distanceCalculatorService = DistanceCalculatorServiceImpl();

    permissionStrategy = PermissionValidatorStrategy(
      permissionService: mockPermissionService,
    );
    gpsStrategy = GpsValidatorStrategy(
      gpsService: mockGpsService,
    );
    distanceStrategy = DistanceValidatorStrategy(
      distanceCalculatorService: distanceCalculatorService,
    );
    wifiStrategy = WifiValidatorStrategy(
      wifiService: mockWifiService,
    );

    repository = AttendanceValidationRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      permissionStrategy: permissionStrategy,
      gpsStrategy: gpsStrategy,
      distanceStrategy: distanceStrategy,
      wifiStrategy: wifiStrategy,
    );

    useCase = ValidateAttendanceUseCase(repository);

    // Default mock behaviors
    when(() => mockRemoteDataSource.getOfficeRule())
        .thenAnswer((_) async => OfficeRuleModel.fromEntity(defaultOfficeRule));
    when(() => mockRemoteDataSource.submitValidationTelemetry(any()))
        .thenAnswer((_) async => true);
  });

  group('ValidateAttendanceUseCase Pipeline', () {
    test('Lolos Validasi (All valid): returns isValid = true', () async {
      // 1. Permission granted
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);

      // 2. GPS enabled & returns office coordinates
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.208810, // ~1 meter from office
                longitude: 106.845605,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));

      // 3. Wi-Fi connected to allowed office SSID
      when(() => mockWifiService.getConnectedWifiInfo())
          .thenAnswer((_) async => WifiInfo.connected(ssid: 'SIP-Office-WiFi'));
      when(() => mockWifiService.isSsidAllowed('SIP-Office-WiFi', any()))
          .thenAnswer((_) async => true);

      final result = await useCase.execute(
        config: ValidationConfig.wfo(officeRule: defaultOfficeRule),
      );

      expect(result.isValid, isTrue);
      expect(result.failure, isNull);
      expect(result.latitude, -6.208810);
      expect(result.ssid, 'SIP-Office-WiFi');
      expect(result.distance, isNotNull);
      expect(result.distance!, lessThan(50.0));
    });

    test('Gagal: Permission ditolak', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockPermissionService.requestLocationPermission())
          .thenAnswer((_) async => PermissionStatus.denied);

      final result = await useCase.execute(
        config: ValidationConfig.wfo(officeRule: defaultOfficeRule),
      );

      expect(result.isValid, isFalse);
      expect(result.failure, isA<PermissionDeniedFailure>());
    });

    test('Gagal: GPS / Lokasi perangkat mati', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      final result = await useCase.execute(
        config: ValidationConfig.wfo(officeRule: defaultOfficeRule),
      );

      expect(result.isValid, isFalse);
      expect(result.failure, isA<GpsDisabledFailure>());
    });

    test('Gagal: Berada di luar radius kantor (> 50 meter)', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.215000, // ~700 meters away
                longitude: 106.845600,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));

      final result = await useCase.execute(
        config: ValidationConfig.wfo(officeRule: defaultOfficeRule),
      );

      expect(result.isValid, isFalse);
      expect(result.failure, isA<OutOfRadiusFailure>());
      expect(result.distance!, greaterThan(50.0));
    });

    test('Gagal: Wi-Fi tidak terhubung ke jaringan kantor', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.208800,
                longitude: 106.845600,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));
      when(() => mockWifiService.getConnectedWifiInfo())
          .thenAnswer((_) async => WifiInfo.connected(ssid: 'Public-Cafe-WiFi'));
      when(() => mockWifiService.isSsidAllowed('Public-Cafe-WiFi', any()))
          .thenAnswer((_) async => false);

      final result = await useCase.execute(
        config: ValidationConfig.wfo(officeRule: defaultOfficeRule),
      );

      expect(result.isValid, isFalse);
      expect(result.failure, isA<WifiNotAllowedFailure>());
    });
  });
}
