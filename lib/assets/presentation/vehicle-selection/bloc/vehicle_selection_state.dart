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
    this.activeSessionId,
    this.ending = false,
    this.endError,
    this.ended = false,
  });

  final VehicleSelectionStatus status;
  final List<Vehicle> vehicles;
  final Object? error;
  final Vehicle? assigned;
  final bool assigning;
  final Object? assignError;

  /// The Driving Session id opened at check-in, retained so the shift can be
  /// ended (check-out). Null when no backend session is active (e.g. a session
  /// with no `driverId`, which is assigned locally only).
  final int? activeSessionId;
  final bool ending;
  final Object? endError;

  /// Set true for one emission right after a successful check-out so the UI
  /// can confirm the shift ended.
  final bool ended;

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
    int? activeSessionId,
    bool clearActiveSessionId = false,
    bool? ending,
    Object? endError,
    bool clearEndError = false,
    bool? ended,
  }) =>
      VehicleSelectionState(
        status: status ?? this.status,
        vehicles: vehicles ?? this.vehicles,
        error: clearError ? null : (error ?? this.error),
        assigned: clearAssigned ? null : (assigned ?? this.assigned),
        assigning: assigning ?? this.assigning,
        assignError:
            clearAssignError ? null : (assignError ?? this.assignError),
        activeSessionId: clearActiveSessionId
            ? null
            : (activeSessionId ?? this.activeSessionId),
        ending: ending ?? this.ending,
        endError: clearEndError ? null : (endError ?? this.endError),
        ended: ended ?? this.ended,
      );

  @override
  List<Object?> get props => [
        status,
        vehicles,
        error,
        assigned,
        assigning,
        assignError,
        activeSessionId,
        ending,
        endError,
        ended,
      ];
}