import 'package:equatable/equatable.dart';
import '../../../domain/entities/safety_alert.dart';

enum SupervisorAlertsStatus { initial, loading, loaded, error }

class SupervisorAlertsState extends Equatable {
  const SupervisorAlertsState({
    this.status = SupervisorAlertsStatus.initial,
    this.alerts = const [],
    this.error,
  });

  final SupervisorAlertsStatus status;
  final List<SafetyAlert> alerts;
  final Object? error;

  SupervisorAlertsState copyWith({
    SupervisorAlertsStatus? status,
    List<SafetyAlert>? alerts,
    Object? error,
    bool clearError = false,
  }) =>
      SupervisorAlertsState(
        status: status ?? this.status,
        alerts: alerts ?? this.alerts,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, alerts, error];
}
