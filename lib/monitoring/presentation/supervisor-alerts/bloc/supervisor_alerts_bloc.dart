import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/monitoring_facade_service.dart';
import 'bloc.dart';

class SupervisorAlertsBloc
    extends Bloc<SupervisorAlertsEvent, SupervisorAlertsState> {
  SupervisorAlertsBloc({required MonitoringFacadeService monitoringFacade})
    : _monitoringFacade = monitoringFacade,
      super(const SupervisorAlertsState()) {
    on<FetchAlertsEvent>(_onFetch);
    on<RefreshAlertsSilentlyEvent>(_onSilentRefresh);
    on<MarkAlertReviewedEvent>(_onMarkReviewed);
  }

  final MonitoringFacadeService _monitoringFacade;

  Future<void> _onFetch(
    FetchAlertsEvent event,
    Emitter<SupervisorAlertsState> emit,
  ) async {
    emit(
      state.copyWith(status: SupervisorAlertsStatus.loading, clearError: true),
    );
    try {
      final alerts = await _monitoringFacade.getAlerts();
      emit(
        state.copyWith(status: SupervisorAlertsStatus.loaded, alerts: alerts),
      );
    } catch (e) {
      emit(state.copyWith(status: SupervisorAlertsStatus.error, error: e));
    }
  }

  /// Silent poll: refresh the list in place. Never shows a skeleton and never
  /// flips into an error state — on failure it simply keeps the current data,
  /// so a transient network blip doesn't disturb the supervisor's view. When it
  /// succeeds the emitted [SupervisorAlertsState] is Equatable-equal if nothing
  /// changed, so the UI (and the new-alert toast listener) only reacts when the
  /// alert set actually changes.
  Future<void> _onSilentRefresh(
    RefreshAlertsSilentlyEvent event,
    Emitter<SupervisorAlertsState> emit,
  ) async {
    try {
      final alerts = await _monitoringFacade.getAlerts();
      emit(
        state.copyWith(
          status: SupervisorAlertsStatus.loaded,
          alerts: alerts,
          clearError: true,
        ),
      );
    } catch (_) {
      // Intentionally swallowed — keep the last good data on-screen.
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
      emit(
        state.copyWith(
          alerts: state.alerts.where((a) => a.id != event.alertId).toList(),
        ),
      );
    }
  }
}
