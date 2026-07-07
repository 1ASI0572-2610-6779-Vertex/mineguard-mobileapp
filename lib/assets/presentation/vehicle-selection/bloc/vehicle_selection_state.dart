import 'package:equatable/equatable.dart';
import '../../../domain/entities/vehicle.dart';

enum VehicleSelectionStatus { initial, loading, loaded, error }

class VehicleSelectionState extends Equatable {
  const VehicleSelectionState({
    this.status = VehicleSelectionStatus.initial,
    this.vehicles = const [],
    this.error,
    this.assigned,
    this.assigning = false,
    this.assignError,
  });

  final VehicleSelectionStatus status;
  final List<Vehicle> vehicles;
  final Object? error;
  final Vehicle? assigned;
  final bool assigning;
  final Object? assignError;

  VehicleSelectionState copyWith({
    VehicleSelectionStatus? status,
    List<Vehicle>? vehicles,
    Object? error,
    bool clearError = false,
    Vehicle? assigned,
    bool clearAssigned = false,
    bool? assigning,
    Object? assignError,
    bool clearAssignError = false,
  }) =>
      VehicleSelectionState(
        status: status ?? this.status,
        vehicles: vehicles ?? this.vehicles,
        error: clearError ? null : (error ?? this.error),
        assigned: clearAssigned ? null : (assigned ?? this.assigned),
        assigning: assigning ?? this.assigning,
        assignError:
            clearAssignError ? null : (assignError ?? this.assignError),
      );

  @override
  List<Object?> get props =>
      [status, vehicles, error, assigned, assigning, assignError];
}
