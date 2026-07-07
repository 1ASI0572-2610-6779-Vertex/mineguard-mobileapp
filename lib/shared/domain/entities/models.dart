// All entities that used to live in this single shared file have moved to
// their owning bounded context (or, for SessionUser/UserRole, stayed a
// shared-kernel type in session_user.dart). This file now only re-exports
// them, so not-yet-migrated files keep compiling during the Bloc migration.
// TODO(migration): delete once every bounded context imports entities
// directly from their new location (step 7 cleanup).
export 'session_user.dart' show SessionUser, UserRole;
export '../../../assets/domain/entities/vehicle.dart'
    show Vehicle, VehicleStatus;
export '../../../monitoring/domain/entities/safety_alert.dart'
    show SafetyAlert, AlertKind;
export '../../../analytics/domain/entities/performance_stats.dart'
    show PerformanceStats;
