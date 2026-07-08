import 'package:dio/dio.dart';
import '../models/performance_dto.dart';

/// Remote data source that consumes the driver performance endpoint.
///
/// Its only responsibility is to perform the HTTP request and translate the
/// JSON response into a `PerformanceDto`.
class PerformanceRemoteDataSource {
  const PerformanceRemoteDataSource(this._dio);

  final Dio _dio;

  /// Fetches the driver's performance from `/drivers/:id/scores`.
  Future<PerformanceDto> getPerformance(int driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/drivers/$driverId/scores',
    );
    return PerformanceDto.fromJson(response.data!);
  }
}
