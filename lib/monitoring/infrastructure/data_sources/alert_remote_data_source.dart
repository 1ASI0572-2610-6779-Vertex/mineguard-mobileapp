import 'package:dio/dio.dart';
import '../models/alert_dto.dart';

class AlertRemoteDataSource {
  const AlertRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AlertDto>> getAlerts() async {
    final response = await _dio.get<List<dynamic>>('/alerts');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(AlertDto.fromJson)
        .toList();
  }

  Future<void> submitAlertAction(String alertId) async {
    await _dio.post<void>('/alerts/$alertId/action');
  }
}
