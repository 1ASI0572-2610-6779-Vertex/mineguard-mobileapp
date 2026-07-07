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

  /// Marks the alert as reviewed/resolved.
  ///
  /// The backend has no dedicated "action" sub-resource for alerts — closing
  /// one is a partial update of the alert itself: `PATCH /alerts/{id}` with
  /// `{"status": "resolved"}`.
  Future<void> submitAlertAction(String alertId) async {
    await _dio.patch<void>(
      '/alerts/$alertId',
      data: {'status': 'resolved'},
    );
  }
}
