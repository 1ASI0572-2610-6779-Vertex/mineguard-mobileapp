import 'package:equatable/equatable.dart';
import '../../../domain/entities/performance_stats.dart';

enum PerformanceStatus { initial, loading, loaded, error }

class PerformanceState extends Equatable {
  const PerformanceState({
    this.status = PerformanceStatus.initial,
    this.stats,
    this.error,
  });

  final PerformanceStatus status;
  final PerformanceStats? stats;
  final Object? error;

  PerformanceState copyWith({
    PerformanceStatus? status,
    PerformanceStats? stats,
    Object? error,
    bool clearError = false,
  }) =>
      PerformanceState(
        status: status ?? this.status,
        stats: stats ?? this.stats,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, stats, error];
}
