import '../entities/vehicle.dart';

/// Domain-level interface defining the contract for vehicle-related operations.
///
/// This abstract interface ensures that the domain layer remains entirely independent
/// of infrastructure details (such as HTTP clients or external APIs). It serves as
/// the Single Source of Truth for what operations can be performed on Vehicles.
abstract interface class VehicleRepository {

  /// Retrieves a comprehensive list of all vehicles available in the system.
  ///
  /// Returns a [Future] that resolves to a [List] of [Vehicle] domain entities.
  Future<List<Vehicle>> getVehicles();

  /// Checks the driver into a vehicle, opening a Driving Session.
  ///
  /// Parameters:
  /// - [vehicleId]: The unique identifier of the selected vehicle.
  /// - [driverId]: The unique identifier of the driver operating the vehicle.
  ///
  /// Returns the opened session's id, retained so the shift can later be
  /// ended via [endShift].
  Future<int> startTrip({required String vehicleId, required int driverId});

  /// Ends the shift by closing the given Driving Session (check-out),
  /// unlinking the driver from the vehicle.
  Future<void> endShift(int sessionId);
}