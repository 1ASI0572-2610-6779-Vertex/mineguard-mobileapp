import 'package:equatable/equatable.dart';

sealed class PerformanceEvent extends Equatable {
  const PerformanceEvent();

  @override
  List<Object?> get props => [];
}

class FetchPerformanceEvent extends PerformanceEvent {
  const FetchPerformanceEvent();
}
