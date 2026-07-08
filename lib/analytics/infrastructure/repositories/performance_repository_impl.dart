import 'package:dio/dio.dart';
import '../../domain/entities/performance_stats.dart';
import '../../../shared/infrastructure/network/app_exception.dart';
import '../../domain/interfaces/performance_repository.dart';
import '../data_sources/performance_remote_data_source.dart';

/// Concrete implementation of the performance repository.
///
/// Acts as an adapter between the remote data source and the domain, turning
/// the network DTO into `PerformanceStats` and normalizing exceptions.
class PerformanceRepositoryImpl implements PerformanceRepository {
  const PerformanceRepositoryImpl(this._dataSource);

  final PerformanceRemoteDataSource _dataSource;

  /// Fetches performance and translates HTTP errors into application
  /// exceptions.
  @override
  Future<PerformanceStats> getPerformance(int driverId) async {
    try {
      final dto = await _dataSource.getPerformance(driverId);
      return dto.toDomain();
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : ServerException(e.message ?? '');
    }
  }
}
