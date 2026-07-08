import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/application/session_cubit.dart';
import '../../../application/assets_facade_service.dart';
import 'bloc.dart';

class VehicleSelectionBloc
    extends Bloc<VehicleSelectionEvent, VehicleSelectionState> {
  VehicleSelectionBloc({
    required AssetsFacadeService assetsFacade,
    required SessionCubit sessionCubit,
  })  : _assetsFacade = assetsFacade,
        _sessionCubit = sessionCubit,
        super(const VehicleSelectionState()) {
    on<FetchVehiclesEvent>(_onFetch);
    on<AssignVehicleEvent>(_onAssign);
    on<EndShiftEvent>(_onEndShift);
  }

  final AssetsFacadeService _assetsFacade;
  final SessionCubit _sessionCubit;

  Future<void> _onFetch(
    FetchVehiclesEvent event,
    Emitter<VehicleSelectionState> emit,
  ) async {
    emit(state.copyWith(
      status: VehicleSelectionStatus.loading,
      clearError: true,
    ));
    try {
      final vehicles = await _assetsFacade.getVehicles();
      emit(state.copyWith(
        status: VehicleSelectionStatus.loaded,
        vehicles: vehicles,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VehicleSelectionStatus.error,
        error: e,
      ));
    }
  }

  Future<void> _onAssign(
    AssignVehicleEvent event,
    Emitter<VehicleSelectionState> emit,
  ) async {
    emit(state.copyWith(assigning: true, clearAssignError: true, ended: false));
    try {
      // If there's no driverId on the session, the vehicle is marked
      // "assigned" locally without opening a backend Driving Session (there's
      // no driver aggregate to check in). With a driverId, we open the session
      // and retain its id so the shift can later be ended.
      final driverId = _sessionCubit.state?.driverId;
      int? sessionId;
      if (driverId != null) {
        sessionId = await _assetsFacade.startTrip(
          vehicleId: event.vehicle.id,
          driverId: driverId,
        );
      }
      emit(state.copyWith(
        assigned: event.vehicle,
        assigning: false,
        activeSessionId: sessionId,
        clearActiveSessionId: sessionId == null,
      ));
    } catch (e) {
      emit(state.copyWith(assigning: false, assignError: e));
    }
  }

  Future<void> _onEndShift(
    EndShiftEvent event,
    Emitter<VehicleSelectionState> emit,
  ) async {
    emit(state.copyWith(ending: true, clearEndError: true, ended: false));
    try {
      // Only call the backend when a real session was opened (driverId
      // present). A locally-only assignment is just cleared.
      final sessionId = state.activeSessionId;
      if (sessionId != null) {
        await _assetsFacade.endShift(sessionId);
      }
      emit(state.copyWith(
        ending: false,
        ended: true,
        clearAssigned: true,
        clearActiveSessionId: true,
      ));
    } catch (e) {
      emit(state.copyWith(ending: false, endError: e));
    }
  }
}
