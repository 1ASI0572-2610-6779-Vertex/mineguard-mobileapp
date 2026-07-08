import '../../../shared/infrastructure/network/app_exception.dart';

/// Read DTO for a Driving Session, as returned by
/// `POST /vehicles/{vehicleId}/driving-sessions` and
/// `PATCH /driving-sessions/{sessionId}`.
///
/// Only [id] and [status] are consumed by the mobile app today — [id] is what
/// the app must retain to later check the driver out (end the shift). The full
/// `DrivingSessionResource` also carries `driverId`, `vehicleId`, `startTime`
/// and `endTime`, parsed lazily here only if present.
class DrivingSessionDto {
  const DrivingSessionDto({required this.id, required this.status});

  final int id;
  final String status;

  factory DrivingSessionDto.fromJson(Map<String, dynamic> json) {
    try {
      return DrivingSessionDto(
        id: (json['id'] as num).toInt(),
        status: json['status'] as String? ?? '',
      );
    } catch (_) {
      throw const ParseException('Invalid driving session response shape');
    }
  }
}