import '../../../shared/domain/entities/models.dart';

/// Contrato de dominio para consultar el desempeño operativo de un conductor.
///
/// La implementación concreta puede obtener los datos desde red, caché u otra
/// fuente, pero siempre debe devolver el modelo agregado `PerformanceStats`.
abstract interface class PerformanceRepository {
  /// Obtiene las métricas de desempeño asociadas al conductor identificado.
  Future<PerformanceStats> getPerformance(int driverId);
}
