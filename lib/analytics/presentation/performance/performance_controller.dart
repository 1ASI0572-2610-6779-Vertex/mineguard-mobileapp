import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_iot/analytics/api/analytics_providers.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';

/// Controlador asíncrono que carga el desempeño del conductor autenticado.
///
/// Lee la sesión activa para resolver el `driverId` y delega la obtención de
/// datos al repositorio de analytics.
class PerformanceController extends AsyncNotifier<PerformanceStats> {
  @override
  /// Construye el estado inicial consultando el desempeño actual del conductor.
  Future<PerformanceStats> build() async {
    final session = ref.watch(sessionProvider);
    final driverId = session?.driverId;
    if (driverId == null) {
      throw StateError('No driverId asociado a este usuario');
    }
    return ref.read(performanceRepositoryProvider).getPerformance(driverId);
  }
}

/// Provider de Riverpod para exponer el estado asíncrono del desempeño.
final performanceControllerProvider =
    AsyncNotifierProvider<PerformanceController, PerformanceStats>(
  PerformanceController.new,
);
