import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/application/session_cubit.dart';
import '../../../../shared/infrastructure/network/app_exception.dart';
import '../../../application/analytics_facade_service.dart';
import '../../../domain/logic/resolve_driver_id.dart';
import 'bloc.dart';

class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  PerformanceBloc({
    required AnalyticsFacadeService analyticsFacade,
    required SessionCubit sessionCubit,
  })  : _analyticsFacade = analyticsFacade,
        _sessionCubit = sessionCubit,
        super(const PerformanceState()) {
    on<FetchPerformanceEvent>(_onFetch);
  }

  final AnalyticsFacadeService _analyticsFacade;
  final SessionCubit _sessionCubit;

  Future<void> _onFetch(
    FetchPerformanceEvent event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(state.copyWith(
      status: PerformanceStatus.loading,
      clearError: true,
    ));
    final driverId = resolveDriverIdOrNull(_sessionCubit.state);
    if (driverId == null) {
      emit(state.copyWith(
        status: PerformanceStatus.error,
        error: const NoDriverIdException(),
      ));
      return;
    }
    try {
      final stats = await _analyticsFacade.getPerformance(driverId);
      emit(state.copyWith(status: PerformanceStatus.loaded, stats: stats));
    } catch (e) {
      emit(state.copyWith(
        status: PerformanceStatus.error,
        error: e,
      ));
    }
  }
}
