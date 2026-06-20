enum UserRole { operator, supervisor }

class SessionUser {
  final String workerId;
  final String fullName;
  final UserRole role;
  final int? driverId;

  const SessionUser({
    required this.workerId,
    required this.fullName,
    required this.role,
    this.driverId,
  });

  bool get isOperator => role == UserRole.operator;
  bool get isSupervisor => role == UserRole.supervisor;
}

enum VehicleStatus { available, inUse, maintenance }

class Vehicle {
  final String id;
  final String name;
  final String category;
  final VehicleStatus status;

  const Vehicle({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
  });
}

class PerformanceStats {
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
}

enum AlertKind { panic, collisionRisk, fatigue }

class SafetyAlert {
  final String id;
  final AlertKind kind;
  final String title;
  final String description;
  final String elapsedLabel;
  final String? primaryAction;

  const SafetyAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.elapsedLabel,
    this.primaryAction,
  });
}
