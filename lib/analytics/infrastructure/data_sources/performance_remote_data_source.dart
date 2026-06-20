import 'package:dio/dio.dart';
import '../models/performance_dto.dart';

class PerformanceRemoteDataSource {
  const PerformanceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PerformanceDto> getPerformance(int driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/drivers/$driverId/performance',
    );
    return PerformanceDto.fromJson(response.data!);
  }
}
