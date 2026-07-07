import 'package:equatable/equatable.dart';
import '../../../domain/entities/performance_stats.dart';

enum PerformanceStatus { initial, loading, loaded, error }

class PerformanceState extends Equatable {
  const PerformanceState({
    this.status = PerformanceStatus.initial,
    this.stats,
    this.errorMessage,
  });

  final PerformanceStatus status;
  final PerformanceStats? stats;
  final String? errorMessage;

  PerformanceState copyWith({
    PerformanceStatus? status,
    PerformanceStats? stats,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) =>
      PerformanceState(
        status: status ?? this.status,
        stats: stats ?? this.stats,
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, stats, errorMessage];
}
