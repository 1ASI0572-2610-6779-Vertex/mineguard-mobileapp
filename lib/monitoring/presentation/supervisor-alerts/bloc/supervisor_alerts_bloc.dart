import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/monitoring_facade_service.dart';
import 'bloc.dart';

class SupervisorAlertsBloc
    extends Bloc<SupervisorAlertsEvent, SupervisorAlertsState> {
  SupervisorAlertsBloc({required MonitoringFacadeService monitoringFacade})
      : _monitoringFacade = monitoringFacade,
        super(const SupervisorAlertsState()) {
    on<FetchAlertsEvent>(_onFetch);
    on<MarkAlertReviewedEvent>(_onMarkReviewed);
  }

  final MonitoringFacadeService _monitoringFacade;

  Future<void> _onFetch(
    FetchAlertsEvent event,
    Emitter<SupervisorAlertsState> emit,
  ) async {
    emit(state.copyWith(
      status: SupervisorAlertsStatus.loading,
      clearError: true,
    ));
    try {
      final alerts = await _monitoringFacade.getAlerts();
      emit(state.copyWith(
        status: SupervisorAlertsStatus.loaded,
        alerts: alerts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SupervisorAlertsStatus.error,
        error: e,
      ));
    }
  }

  // Preserved from the original controller: no try/catch here — if
  // submitAlertAction throws, it's not turned into an error state, matching
  // today's unhandled-propagation behavior.
  Future<void> _onMarkReviewed(
    MarkAlertReviewedEvent event,
    Emitter<SupervisorAlertsState> emit,
  ) async {
    await _monitoringFacade.submitAlertAction(event.alertId);
    if (state.status == SupervisorAlertsStatus.loaded) {
      emit(state.copyWith(
        alerts:
            state.alerts.where((a) => a.id != event.alertId).toList(),
      ));
    }
  }
}
