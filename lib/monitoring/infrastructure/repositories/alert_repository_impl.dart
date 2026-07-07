import 'package:dio/dio.dart';
import '../../domain/entities/safety_alert.dart';
import '../../../shared/infrastructure/network/app_exception.dart';
import '../../domain/interfaces/alert_repository.dart';
import '../data_sources/alert_remote_data_source.dart';

class AlertRepositoryImpl implements AlertRepository {
  const AlertRepositoryImpl(this._dataSource);

  final AlertRemoteDataSource _dataSource;

  @override
  Future<List<SafetyAlert>> getAlerts() async {
    try {
      final dtos = await _dataSource.getAlerts();
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : ServerException(e.message ?? '');
    }
  }

  @override
  Future<void> submitAlertAction(String alertId) async {
    try {
      await _dataSource.submitAlertAction(alertId);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : ServerException(e.message ?? '');
    }
  }
}
