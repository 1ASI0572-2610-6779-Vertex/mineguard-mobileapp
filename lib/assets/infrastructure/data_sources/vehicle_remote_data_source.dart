import 'package:dio/dio.dart';
import '../models/driving_session_dto.dart';
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

  /// Checks the driver into a vehicle — opens a Driving Session
  /// (`POST /vehicles/{vehicleId}/driving-sessions`). Returns the created
  /// session so the caller can retain its `id` for the later check-out.
  Future<DrivingSessionDto> startTrip({
    required String vehicleId,
    required int driverId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/vehicles/$vehicleId/driving-sessions',
      data: {'driverId': driverId},
    );
    return DrivingSessionDto.fromJson(response.data!);
  }

  /// Ends the shift by closing the Driving Session
  /// (`PATCH /driving-sessions/{sessionId}` with `{"status": "COMPLETED"}`),
  /// which stamps the server-side `endTime` and unlinks the driver from the
  /// vehicle.
  Future<void> endShift(int sessionId) async {
    await _dio.patch<void>(
      '/driving-sessions/$sessionId',
      data: {'status': 'COMPLETED'},
    );
  }
}
