import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_iot/analytics/api/analytics_providers.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';

class PerformanceController extends AsyncNotifier<PerformanceStats> {
  @override
  Future<PerformanceStats> build() async {
    final session = ref.watch(sessionProvider);
    final driverId = session?.driverId;
    if (driverId == null) {
      throw StateError('No driverId asociado a este usuario');
    }
    return ref.read(performanceRepositoryProvider).getPerformance(driverId);
  }
}

final performanceControllerProvider =
    AsyncNotifierProvider<PerformanceController, PerformanceStats>(
  PerformanceController.new,
);
