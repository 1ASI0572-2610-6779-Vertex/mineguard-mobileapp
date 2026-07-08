import '../domain/entities/vehicle.dart';
import '../domain/interfaces/vehicle_repository.dart';

class AssetsFacadeService {
  const AssetsFacadeService({required this.repository});

  final VehicleRepository repository;

  Future<List<Vehicle>> getVehicles() => repository.getVehicles();

  Future<int> startTrip({required String vehicleId, required int driverId}) =>
      repository.startTrip(vehicleId: vehicleId, driverId: driverId);

  Future<void> endShift(int sessionId) => repository.endShift(sessionId);
}
