import '../../../shared/domain/entities/models.dart';

abstract interface class VehicleRepository {
  /// Returns the operator's vehicle roster.
  /// The UI only renders three statuses; mapping happens in the DTO layer.
  Future<List<Vehicle>> getVehicles();
}
