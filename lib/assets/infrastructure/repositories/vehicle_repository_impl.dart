import 'package:dio/dio.dart';
import '../../domain/entities/vehicle.dart';
import '../../../shared/infrastructure/network/app_exception.dart';
import '../../domain/interfaces/vehicle_repository.dart';
import '../data_sources/vehicle_remote_data_source.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  const VehicleRepositoryImpl(this._dataSource);

  final VehicleRemoteDataSource _dataSource;

  @override
  Future<List<Vehicle>> getVehicles() async {
    try {
      final dtos = await _dataSource.getVehicles();
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : ServerException(e.message ?? '');
    }
  }

  @override
  Future<int> startTrip({
    required String vehicleId,
    required int driverId,
  }) async {
    try {
      final session =
          await _dataSource.startTrip(vehicleId: vehicleId, driverId: driverId);
      return session.id;
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : ServerException(e.message ?? '');
    }
  }

  @override
  Future<void> endShift(int sessionId) async {
    try {
      await _dataSource.endShift(sessionId);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : ServerException(e.message ?? '');
    }
  }
}
