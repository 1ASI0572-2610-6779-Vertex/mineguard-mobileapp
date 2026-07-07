import 'package:equatable/equatable.dart';

class PerformanceStats extends Equatable {
  final int safetyScore;
  final int safetyScoreDelta;
  final int fatigueAlerts;
  final double drivingHours;
  final double drivingHoursLimit;

  const PerformanceStats({
    required this.safetyScore,
    required this.safetyScoreDelta,
    required this.fatigueAlerts,
    required this.drivingHours,
    required this.drivingHoursLimit,
  });

  @override
  List<Object?> get props =>
      [safetyScore, safetyScoreDelta, fatigueAlerts, drivingHours, drivingHoursLimit];
}
