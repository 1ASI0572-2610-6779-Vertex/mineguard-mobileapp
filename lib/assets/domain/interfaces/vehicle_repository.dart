import '../../../shared/domain/entities/models.dart';

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

  /// Initiates a trip for a designated vehicle operated by a specific driver.
  ///
  /// This method maps directly to the "Driver Management" business requirements.
  ///
  /// Parameters:
  /// - [vehicleId]: The unique identifier of the selected vehicle.
  /// - [driverId]: The unique identifier of the driver operating the vehicle.
  Future<void> startTrip({required String vehicleId, required int driverId});
}