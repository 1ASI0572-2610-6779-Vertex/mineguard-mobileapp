import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

/// DTO de lectura para el desempeño del conductor.
///
/// No realiza transformaciones de negocio: los nombres y tipos de campos se
/// alinean directamente con el contrato del API y luego se mapean al modelo de
/// dominio `PerformanceStats`.
class PerformanceDto {
  const PerformanceDto({
    required this.safetyScore,
    required this.safetyScoreDelta,
    required this.fatigueAlerts,
    required this.drivingHours,
    required this.drivingHoursLimit,
  });

  final int safetyScore;
  final int safetyScoreDelta;
  final int fatigueAlerts;
  final double drivingHours;
  final double drivingHoursLimit;

  /// Construye el DTO a partir del JSON del backend.
  ///
  /// Se acepta que algunos entornos serialicen horas como `int`; por eso se
  /// normalizan a `double`. Si la estructura no coincide, se lanza
  /// `ParseException`.
  factory PerformanceDto.fromJson(Map<String, dynamic> json) {
    try {
      return PerformanceDto(
        safetyScore: json['safetyScore'] as int,
        safetyScoreDelta: json['safetyScoreDelta'] as int,
        fatigueAlerts: json['fatigueAlerts'] as int,
        // Backend may send these as int in some environments
        drivingHours: (json['drivingHours'] as num).toDouble(),
        drivingHoursLimit: (json['drivingHoursLimit'] as num).toDouble(),
      );
    } catch (_) {
      throw const ParseException('Invalid performance response shape');
    }
  }

  /// Convierte el DTO a la entidad de dominio utilizada por la UI.
  PerformanceStats toDomain() => PerformanceStats(
        safetyScore: safetyScore,
        safetyScoreDelta: safetyScoreDelta,
        fatigueAlerts: fatigueAlerts,
        drivingHours: drivingHours,
        drivingHoursLimit: drivingHoursLimit,
      );
}
