import 'package:equatable/equatable.dart';
import '../../domain/entities/validation_failure.dart';
import '../../domain/entities/validation_result.dart';
import '../../domain/entities/validation_step_status.dart';

abstract class AttendanceValidationState extends Equatable {
  const AttendanceValidationState();

  @override
  List<Object?> get props => [];
}

class AttendanceValidationInitial extends AttendanceValidationState {
  const AttendanceValidationInitial();
}

class AttendanceValidationInProgress extends AttendanceValidationState {
  final String activeStepKey;
  final String activeStepName;
  final Map<String, ValidationStepStatus> stepStatuses;

  const AttendanceValidationInProgress({
    required this.activeStepKey,
    required this.activeStepName,
    required this.stepStatuses,
  });

  @override
  List<Object?> get props => [activeStepKey, activeStepName, stepStatuses];
}

class AttendanceValidationSuccess extends AttendanceValidationState {
  final ValidationResult result;

  const AttendanceValidationSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

class AttendanceValidationFailureState extends AttendanceValidationState {
  final ValidationResult result;
  final ValidationFailure failure;
  final String? directActionLabel;
  final String? directActionType; // 'open_settings', 'enable_gps', 'connect_wifi', 'retry'

  const AttendanceValidationFailureState({
    required this.result,
    required this.failure,
    this.directActionLabel,
    this.directActionType,
  });

  @override
  List<Object?> get props => [
        result,
        failure,
        directActionLabel,
        directActionType,
      ];
}
