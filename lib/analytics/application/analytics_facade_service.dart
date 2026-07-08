import '../domain/entities/performance_stats.dart';
import '../domain/interfaces/performance_repository.dart';

class AnalyticsFacadeService {
  const AnalyticsFacadeService({required this.repository});

  final PerformanceRepository repository;

  Future<PerformanceStats> getPerformance(int driverId) =>
      repository.getPerformance(driverId);
}
