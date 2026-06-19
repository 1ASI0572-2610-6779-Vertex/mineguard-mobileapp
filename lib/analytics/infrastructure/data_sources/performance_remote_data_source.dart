import 'package:dio/dio.dart';
import '../models/performance_dto.dart';

class PerformanceRemoteDataSource {
  const PerformanceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PerformanceDto> getPerformance(String workerId) async {
    final response = await _dio.get<Map<String, dynamic>>('/performance/$workerId');
    return PerformanceDto.fromJson(response.data!);
  }
}
