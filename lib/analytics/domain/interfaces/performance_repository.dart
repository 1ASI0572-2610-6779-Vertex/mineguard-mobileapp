import '../../../shared/domain/entities/models.dart';

abstract interface class PerformanceRepository {
  Future<PerformanceStats> getPerformance(int driverId);
}
