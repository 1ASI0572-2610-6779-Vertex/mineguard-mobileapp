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
  }

  final AssetsFacadeService _assetsFacade;
  final SessionCubit _sessionCubit;

  Future<void> _onFetch(
    FetchVehiclesEvent event,
    Emitter<VehicleSelectionState> emit,
  ) async {
    emit(state.copyWith(
      status: VehicleSelectionStatus.loading,
      clearErrorMessage: true,
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
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAssign(
    AssignVehicleEvent event,
    Emitter<VehicleSelectionState> emit,
  ) async {
    emit(state.copyWith(assigning: true, clearAssignError: true));
    try {
      // Preserved from the original controller: if there's no driverId on
      // the session, the vehicle is still marked "assigned" locally without
      // ever calling the backend. Not a bug to fix here, just to preserve.
      final driverId = _sessionCubit.state?.driverId;
      if (driverId != null) {
        await _assetsFacade.startTrip(
          vehicleId: event.vehicle.id,
          driverId: driverId,
        );
      }
      emit(state.copyWith(assigned: event.vehicle, assigning: false));
    } catch (e) {
      emit(state.copyWith(assigning: false, assignError: e.toString()));
    }
  }
}
