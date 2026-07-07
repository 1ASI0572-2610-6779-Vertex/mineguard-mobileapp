import 'package:dio/dio.dart';
import '../models/vehicle_dto.dart';

class VehicleRemoteDataSource {
  const VehicleRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<VehicleDto>> getVehicles() async {
    final response = await _dio.get<List<dynamic>>('/vehicles');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(VehicleDto.fromJson)
        .toList();
  }

  Future<void> startTrip({
    required String vehicleId,
    required int driverId,
  }) async {
    await _dio.post<void>(
      '/vehicles/$vehicleId/driving-sessions',
      data: {'driverId': driverId},
    );
  }
}
