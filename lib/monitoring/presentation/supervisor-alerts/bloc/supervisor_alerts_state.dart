import 'package:equatable/equatable.dart';
import '../../../domain/entities/safety_alert.dart';

enum SupervisorAlertsStatus { initial, loading, loaded, error }

class SupervisorAlertsState extends Equatable {
  const SupervisorAlertsState({
    this.status = SupervisorAlertsStatus.initial,
    this.alerts = const [],
    this.errorMessage,
  });

  final SupervisorAlertsStatus status;
  final List<SafetyAlert> alerts;
  final String? errorMessage;

  SupervisorAlertsState copyWith({
    SupervisorAlertsStatus? status,
    List<SafetyAlert>? alerts,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) =>
      SupervisorAlertsState(
        status: status ?? this.status,
        alerts: alerts ?? this.alerts,
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, alerts, errorMessage];
}
