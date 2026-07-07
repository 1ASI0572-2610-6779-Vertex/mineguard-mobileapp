import '../entities/performance_stats.dart';

/// Domain contract for querying a driver's operational performance.
///
/// The concrete implementation may fetch data from the network, cache, or
/// another source, but must always return the aggregate `PerformanceStats`
/// model.
abstract interface class PerformanceRepository {
  /// Fetches the performance metrics for the given driver.
  Future<PerformanceStats> getPerformance(int driverId);
}
