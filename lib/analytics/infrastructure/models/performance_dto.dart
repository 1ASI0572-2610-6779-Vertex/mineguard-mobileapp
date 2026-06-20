import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

/// No value transformation — field names and types match the API contract
/// exactly, per the business rule that this is a read-only view-model.
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

  PerformanceStats toDomain() => PerformanceStats(
        safetyScore: safetyScore,
        safetyScoreDelta: safetyScoreDelta,
        fatigueAlerts: fatigueAlerts,
        drivingHours: drivingHours,
        drivingHoursLimit: drivingHoursLimit,
      );
}
