import 'package:dio/dio.dart';
import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';
import '../../domain/interfaces/performance_repository.dart';
import '../data_sources/performance_remote_data_source.dart';

class PerformanceRepositoryImpl implements PerformanceRepository {
  const PerformanceRepositoryImpl(this._dataSource);

  final PerformanceRemoteDataSource _dataSource;

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
