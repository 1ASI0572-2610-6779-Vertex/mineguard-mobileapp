import 'package:equatable/equatable.dart';

sealed class SupervisorAlertsEvent extends Equatable {
  const SupervisorAlertsEvent();

  @override
  List<Object?> get props => [];
}

class FetchAlertsEvent extends SupervisorAlertsEvent {
  const FetchAlertsEvent();
}

/// Background refresh that does NOT flip the UI into a loading/skeleton state.
/// Dispatched on a timer so newly-arrived backend alerts surface automatically
/// without disrupting what the supervisor is looking at.
class RefreshAlertsSilentlyEvent extends SupervisorAlertsEvent {
  const RefreshAlertsSilentlyEvent();
}

class MarkAlertReviewedEvent extends SupervisorAlertsEvent {
  const MarkAlertReviewedEvent(this.alertId);

  final String alertId;

  @override
  List<Object?> get props => [alertId];
}
