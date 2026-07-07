import 'package:equatable/equatable.dart';

sealed class SupervisorAlertsEvent extends Equatable {
  const SupervisorAlertsEvent();

  @override
  List<Object?> get props => [];
}

class FetchAlertsEvent extends SupervisorAlertsEvent {
  const FetchAlertsEvent();
}

class MarkAlertReviewedEvent extends SupervisorAlertsEvent {
  const MarkAlertReviewedEvent(this.alertId);

  final String alertId;

  @override
  List<Object?> get props => [alertId];
}
