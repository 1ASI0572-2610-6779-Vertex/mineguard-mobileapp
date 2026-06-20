import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_iot/assets/api/assets_providers.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';

class VehicleSelectionState {
  const VehicleSelectionState({
    this.vehicles = const AsyncLoading(),
    this.assigned,
    this.assigning = false,
    this.assignError,
  });

  final AsyncValue<List<Vehicle>> vehicles;
  final Vehicle? assigned;
  final bool assigning;
  final String? assignError;

  VehicleSelectionState copyWith({
    AsyncValue<List<Vehicle>>? vehicles,
    Vehicle? assigned,
    bool clearAssigned = false,
    bool? assigning,
    String? assignError,
    bool clearError = false,
  }) =>
      VehicleSelectionState(
        vehicles: vehicles ?? this.vehicles,
        assigned: clearAssigned ? null : (assigned ?? this.assigned),
        assigning: assigning ?? this.assigning,
        assignError: clearError ? null : (assignError ?? this.assignError),
      );
}

class VehicleSelectionController extends Notifier<VehicleSelectionState> {
  @override
  VehicleSelectionState build() {
    _fetchVehicles();
    return const VehicleSelectionState();
  }

  Future<void> _fetchVehicles() async {
    state = state.copyWith(vehicles: const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(vehicleRepositoryProvider).getVehicles(),
    );
    state = state.copyWith(vehicles: result);
  }

  Future<void> assignVehicle(Vehicle vehicle) async {
    final session = ref.read(sessionProvider);
    state = state.copyWith(assigning: true, clearError: true);
    try {
      if (session?.driverId != null) {
        await ref.read(vehicleRepositoryProvider).startTrip(
              vehicleId: vehicle.id,
              driverId: session!.driverId!,
            );
      }
      state = state.copyWith(assigned: vehicle, assigning: false);
    } catch (e) {
      state = state.copyWith(
        assigning: false,
        assignError: e.toString(),
      );
    }
  }

  Future<void> refresh() => _fetchVehicles();
}

final vehicleSelectionControllerProvider =
    NotifierProvider<VehicleSelectionController, VehicleSelectionState>(
  VehicleSelectionController.new,
);
