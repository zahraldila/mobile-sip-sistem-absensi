import '../entities/office_rule.dart';
import '../entities/validation_config.dart';
import '../entities/validation_failure.dart';
import '../entities/validation_step_status.dart';

class ValidationContext {
  final ValidationConfig config;
  final List<OfficeRule> officeRules;

  OfficeRule get officeRule =>
      matchedOfficeRule ??
      (officeRules.isNotEmpty
          ? officeRules.first
          : OfficeRule.defaultOffice());

  // Mutated / accumulated during the validation pipeline
  OfficeRule? matchedOfficeRule;
  bool isPermissionGranted;
  bool isGpsEnabled;
  bool isDistanceValid;
  bool isWifiValid;
  double? latitude;
  double? longitude;
  double? accuracy;
  double? distance;
  String? ssid;
  String? bssid;
  ValidationFailure? failure;
  final Map<String, ValidationStepStatus> stepDetails;

  ValidationContext({
    required this.config,
    List<OfficeRule>? officeRules,
    OfficeRule? officeRule,
    this.matchedOfficeRule,
    this.isPermissionGranted = false,
    this.isGpsEnabled = false,
    this.isDistanceValid = false,
    this.isWifiValid = false,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distance,
    this.ssid,
    this.bssid,
    this.failure,
    Map<String, ValidationStepStatus>? stepDetails,
  })  : officeRules = officeRules ??
            (officeRule != null
                ? [officeRule]
                : (config.customOfficeRules ?? [OfficeRule.defaultOffice()])),
        stepDetails = stepDetails ?? {};
}

class ValidationStepResult {
  final bool isPassed;
  final ValidationFailure? failure;
  final bool shouldHalt;

  const ValidationStepResult.passed()
      : isPassed = true,
        failure = null,
        shouldHalt = false;

  const ValidationStepResult.failed(this.failure, {this.shouldHalt = true})
      : isPassed = false;

  const ValidationStepResult.skipped()
      : isPassed = true,
        failure = null,
        shouldHalt = false;
}

abstract class AttendanceValidatorStrategy {
  String get stepKey;
  String get displayName;
  Future<ValidationStepResult> validate(ValidationContext context);
}
