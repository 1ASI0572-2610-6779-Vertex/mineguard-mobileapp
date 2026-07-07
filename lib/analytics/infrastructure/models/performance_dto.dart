import '../../domain/entities/performance_stats.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

/// Read DTO for a driver's performance.
///
/// Performs no business transformation: field names and types map directly
/// to the API contract, then get converted to the `PerformanceStats` domain
/// model.
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

  /// Builds the DTO from the backend's JSON response.
  ///
  /// Some environments serialize hours as `int`, so they're normalized to
  /// `double`. Throws [ParseException] if the shape doesn't match.
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

  /// Converts the DTO into the domain entity consumed by the UI.
  PerformanceStats toDomain() => PerformanceStats(
        safetyScore: safetyScore,
        safetyScoreDelta: safetyScoreDelta,
        fatigueAlerts: fatigueAlerts,
        drivingHours: drivingHours,
        drivingHoursLimit: drivingHoursLimit,
      );
}
