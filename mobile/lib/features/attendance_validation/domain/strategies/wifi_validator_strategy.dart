import '../../services/wifi_service.dart';
import '../entities/office_rule.dart';
import '../entities/validation_failure.dart';
import '../entities/validation_step_status.dart';
import 'attendance_validator_strategy.dart';

class WifiValidatorStrategy implements AttendanceValidatorStrategy {
  final WifiService wifiService;

  WifiValidatorStrategy({required this.wifiService});

  @override
  String get stepKey => 'wifi';

  @override
  String get displayName => 'Koneksi Wi-Fi Kantor';

  @override
  Future<ValidationStepResult> validate(ValidationContext context) async {
    if (!context.config.requireWifi) {
      context.stepDetails[stepKey] = ValidationStepStatus.skipped;
      return const ValidationStepResult.skipped();
    }

    context.stepDetails[stepKey] = ValidationStepStatus.running;

    try {
      final wifiInfo = await wifiService.getConnectedWifiInfo();

      if (!wifiInfo.isConnected || wifiInfo.ssid == null || wifiInfo.ssid!.isEmpty) {
        context.isWifiValid = false;
        context.stepDetails[stepKey] = ValidationStepStatus.failed;
        const failure = WifiNotConnectedFailure();
        context.failure ??= failure;
        return const ValidationStepResult.failed(failure, shouldHalt: false);
      }

      context.ssid = wifiInfo.ssid;
      context.bssid = wifiInfo.bssid;

      final offices = context.officeRules.isNotEmpty
          ? context.officeRules
          : [context.officeRule];

      final allAllowedSsids = <String>{};
      OfficeRule? matchingOffice;

      for (final office in offices) {
        allAllowedSsids.addAll(office.allowedSsids);
        final matchesOffice = await wifiService.isSsidAllowed(
          wifiInfo.ssid!,
          office.allowedSsids,
        );
        if (matchesOffice && matchingOffice == null) {
          matchingOffice = office;
        }
      }

      if (matchingOffice != null) {
        context.isWifiValid = true;
        context.matchedOfficeRule ??= matchingOffice;
        context.stepDetails[stepKey] = ValidationStepStatus.passed;
        return const ValidationStepResult.passed();
      }

      context.isWifiValid = false;
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      final failure = WifiNotAllowedFailure(
        currentSsid: wifiInfo.ssid!,
        allowedSsids: allAllowedSsids.toList(),
        message:
            'Jaringan Wi-Fi "${wifiInfo.ssid}" tidak terdaftar sebagai Wi-Fi resmi kantor.',
        actionHint:
            'Silakan hubungkan perangkat Anda ke salah satu Wi-Fi kantor: ${allAllowedSsids.join(", ")}.',
      );
      context.failure ??= failure;
      return ValidationStepResult.failed(failure, shouldHalt: false);
    } catch (e) {
      context.isWifiValid = false;
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      final failure = UnknownValidationFailure(
        error: e.toString(),
        message: 'Gagal memverifikasi koneksi Wi-Fi kantor.',
      );
      context.failure ??= failure;
      return ValidationStepResult.failed(failure, shouldHalt: false);
    }
  }
}
