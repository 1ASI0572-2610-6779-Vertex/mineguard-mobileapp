import '../../../shared/domain/entities/models.dart';

abstract interface class VehicleRepository {
  Future<List<Vehicle>> getVehicles();
  Future<void> startTrip({required String vehicleId, required int driverId});
}
