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

  final officeJakarta = const OfficeRule(
    id: 'OFFICE-JKT-001',
    officeName: 'Kantor Pusat Jakarta',
    latitude: -6.208800,
    longitude: 106.845600,
    maxRadiusMeters: 50.0,
    allowedSsids: ['SIP-Jakarta-WiFi', 'SELADA-WIFI'],
  );

  final officeBandung = const OfficeRule(
    id: 'OFFICE-BDG-002',
    officeName: 'Kantor Cabang Bandung',
    latitude: -6.910194,
    longitude: 107.650728,
    maxRadiusMeters: 50.0,
    allowedSsids: ['SIP-Bandung-WiFi', 'SELADA-WIFI'],
  );

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
    when(() => mockRemoteDataSource.getOfficeRules())
        .thenAnswer((_) async => [
              OfficeRuleModel.fromEntity(officeJakarta),
              OfficeRuleModel.fromEntity(officeBandung),
            ]);
    when(() => mockRemoteDataSource.getOfficeRule())
        .thenAnswer((_) async => OfficeRuleModel.fromEntity(officeJakarta));
    when(() => mockRemoteDataSource.submitValidationTelemetry(any()))
        .thenAnswer((_) async => true);
  });

  group('ValidateAttendanceUseCase Pipeline Multi-Office (WFO OR Logic)', () {
    test('Lolos: Berada dalam radius Kantor Jakarta dan Wi-Fi Jakarta terhubung', () async {
      // 1. Permission granted
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);

      // 2. GPS enabled & returns Jakarta office coordinates (~1 meter away)
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.208810,
                longitude: 106.845605,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));

      // 3. Wi-Fi connected to Jakarta SSID
      when(() => mockWifiService.getConnectedWifiInfo())
          .thenAnswer((_) async => WifiInfo.connected(ssid: 'SIP-Jakarta-WiFi'));
      when(() => mockWifiService.isSsidAllowed('SIP-Jakarta-WiFi', any()))
          .thenAnswer((_) async => true);

      final result = await useCase.validasiWFO(
        officeRules: [officeJakarta, officeBandung],
      );

      expect(result.isValid, isTrue);
      expect(result.failure, isNull);
      expect(result.latitude, -6.208810);
      expect(result.ssid, 'SIP-Jakarta-WiFi');
      expect(result.distance, isNotNull);
      expect(result.distance!, lessThan(50.0));
    });

    test('Lolos: Berada di Kantor Cabang Bandung (Valid ke kantor cabang mana saja)', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.910200, // In Bandung office
                longitude: 107.650730,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));
      when(() => mockWifiService.getConnectedWifiInfo())
          .thenAnswer((_) async => WifiInfo.connected(ssid: 'SIP-Bandung-WiFi'));
      when(() => mockWifiService.isSsidAllowed('SIP-Bandung-WiFi', any()))
          .thenAnswer((invocation) {
            final allowed = invocation.positionalArguments[1] as List<String>;
            return Future.value(allowed.contains('SIP-Bandung-WiFi'));
          });

      final result = await useCase.validasiWFO(
        officeRules: [officeJakarta, officeBandung],
      );

      expect(result.isValid, isTrue);
      expect(result.failure, isNull);
      expect(result.ssid, 'SIP-Bandung-WiFi');
      expect(result.distance!, lessThan(50.0));
    });

    test('Lolos: Dalam radius Kantor Jakarta meskipun Wi-Fi bukan Wi-Fi kantor (OR condition)', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.208810, // ~1 meter from Jakarta Office
                longitude: 106.845605,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));
      when(() => mockWifiService.getConnectedWifiInfo())
          .thenAnswer((_) async => WifiInfo.connected(ssid: 'Personal-Hotspot'));
      when(() => mockWifiService.isSsidAllowed('Personal-Hotspot', any()))
          .thenAnswer((_) async => false);

      final result = await useCase.validasiWFO(
        officeRules: [officeJakarta, officeBandung],
      );

      expect(result.isValid, isTrue);
      expect(result.failure, isNull);
      expect(result.distance!, lessThan(50.0));
    });

    test('Lolos: Di luar radius semua kantor tetapi terhubung ke Wi-Fi Kantor (OR condition)', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.220000, // Outside radius (>1km away)
                longitude: 106.850000,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));
      when(() => mockWifiService.getConnectedWifiInfo())
          .thenAnswer((_) async => WifiInfo.connected(ssid: 'SIP-Jakarta-WiFi'));
      when(() => mockWifiService.isSsidAllowed('SIP-Jakarta-WiFi', any()))
          .thenAnswer((invocation) {
            final allowed = invocation.positionalArguments[1] as List<String>;
            return Future.value(allowed.contains('SIP-Jakarta-WiFi'));
          });

      final result = await useCase.validasiWFO(
        officeRules: [officeJakarta, officeBandung],
      );

      expect(result.isValid, isTrue);
      expect(result.failure, isNull);
      expect(result.ssid, 'SIP-Jakarta-WiFi');
    });

    test('Gagal: Di luar radius SEMUA kantor DAN Wi-Fi bukan Wi-Fi kantor', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
          .thenAnswer((_) async => DevicePosition(
                latitude: -6.300000, // Far away
                longitude: 106.900000,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ));
      when(() => mockWifiService.getConnectedWifiInfo())
          .thenAnswer((_) async => WifiInfo.connected(ssid: 'Public-Cafe-WiFi'));
      when(() => mockWifiService.isSsidAllowed('Public-Cafe-WiFi', any()))
          .thenAnswer((_) async => false);

      final result = await useCase.validasiWFO(
        officeRules: [officeJakarta, officeBandung],
      );

      expect(result.isValid, isFalse);
      expect(result.failure, isNotNull);
    });

    test('Gagal: Permission lokasi ditolak', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockPermissionService.requestLocationPermission())
          .thenAnswer((_) async => PermissionStatus.denied);

      final result = await useCase.validasiWFO(
        officeRules: [officeJakarta, officeBandung],
      );

      expect(result.isValid, isFalse);
      expect(result.failure, isA<PermissionDeniedFailure>());
    });

    test('Gagal: Layanan GPS dimatikan di perangkat', () async {
      when(() => mockPermissionService.isLocationPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockGpsService.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      final result = await useCase.validasiWFO(
        officeRules: [officeJakarta, officeBandung],
      );

      expect(result.isValid, isFalse);
      expect(result.failure, isA<GpsDisabledFailure>());
    });
  });
}
