import 'package:dio/dio.dart';
import '../models/performance_dto.dart';

/// Fuente remota encargada de consumir el endpoint de desempeño del conductor.
///
/// Su única responsabilidad es ejecutar la petición HTTP y traducir la
/// respuesta JSON en un `PerformanceDto`.
class PerformanceRemoteDataSource {
  const PerformanceRemoteDataSource(this._dio);

  final Dio _dio;

  /// Obtiene el desempeño del conductor en el endpoint `/drivers/:id/performance`.
  Future<PerformanceDto> getPerformance(int driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/drivers/$driverId/performance',
    );
    return PerformanceDto.fromJson(response.data!);
  }
}
