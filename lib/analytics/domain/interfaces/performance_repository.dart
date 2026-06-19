import '../../../shared/domain/entities/models.dart';

abstract interface class PerformanceRepository {
  /// Fetches the current shift stats for [workerId].
  /// The business rule: this is a view-model — no transformation, display as-is.
  Future<PerformanceStats> getPerformance(String workerId);
}
