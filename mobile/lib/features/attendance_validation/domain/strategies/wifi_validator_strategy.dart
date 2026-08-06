import '../../services/wifi_service.dart';
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
        context.stepDetails[stepKey] = ValidationStepStatus.failed;
        const failure = WifiNotConnectedFailure();
        context.failure = failure;
        return const ValidationStepResult.failed(failure);
      }

      context.ssid = wifiInfo.ssid;
      context.bssid = wifiInfo.bssid;

      final isAllowed = await wifiService.isSsidAllowed(
        wifiInfo.ssid!,
        context.officeRule.allowedSsids,
      );

      if (!isAllowed) {
        context.stepDetails[stepKey] = ValidationStepStatus.failed;
        final failure = WifiNotAllowedFailure(
          currentSsid: wifiInfo.ssid!,
          allowedSsids: context.officeRule.allowedSsids,
          message:
              'Jaringan Wi-Fi "${wifiInfo.ssid}" tidak terdaftar sebagai Wi-Fi resmi kantor.',
          actionHint:
              'Silakan hubungkan perangkat Anda ke salah satu Wi-Fi kantor: ${context.officeRule.allowedSsids.join(", ")}.',
        );
        context.failure = failure;
        return ValidationStepResult.failed(failure);
      }

      context.stepDetails[stepKey] = ValidationStepStatus.passed;
      return const ValidationStepResult.passed();
    } catch (e) {
      context.stepDetails[stepKey] = ValidationStepStatus.failed;
      final failure = UnknownValidationFailure(
        error: e.toString(),
        message: 'Gagal memverifikasi koneksi Wi-Fi kantor.',
      );
      context.failure = failure;
      return ValidationStepResult.failed(failure);
    }
  }
}
