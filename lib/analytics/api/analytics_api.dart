import '../../injections.dart';
import '../presentation/performance/bloc/performance_bloc.dart';

/// Public cross-context boundary for `analytics`.
class AnalyticsApi {
  /// Discards the cached [PerformanceBloc] singleton so the next screen
  /// mount starts fresh — called on logout to avoid leaking one driver's
  /// performance data into the next driver's session.
  void resetPerformanceState() =>
      serviceLocator.resetLazySingleton<PerformanceBloc>();
}
