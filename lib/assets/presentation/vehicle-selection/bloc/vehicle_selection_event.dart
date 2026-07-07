import 'package:equatable/equatable.dart';
import '../../../domain/entities/vehicle.dart';

sealed class VehicleSelectionEvent extends Equatable {
  const VehicleSelectionEvent();

  @override
  List<Object?> get props => [];
}

class FetchVehiclesEvent extends VehicleSelectionEvent {
  const FetchVehiclesEvent();
}

class AssignVehicleEvent extends VehicleSelectionEvent {
  const AssignVehicleEvent(this.vehicle);

  final Vehicle vehicle;

  @override
  List<Object?> get props => [vehicle];
}
