import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

/// A Data Transfer Object (DTO) that represents the raw vehicle data
/// received from external APIs or backend services.
///
/// This class acts as a boundary between the external world (JSON) and the
/// internal application architecture. It is responsible for safely parsing
/// incoming data and translating it into pure [Vehicle] domain entities.
class VehicleDto {
  /// Creates an immutable [VehicleDto] instance.
  const VehicleDto({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
  });

  /// The unique identifier of the vehicle as provided by the backend.
  final String id;

  /// The display name or model of the vehicle.
  final String name;

  /// The classification or type of the vehicle (e.g., 'truck', 'excavator').
  final String category;

  /// The raw status string provided by the backend endpoint.
  final String status;

  /// Safely parses a JSON map into a [VehicleDto].
  ///
  /// Throws a [ParseException] if the JSON structure is malformed or missing
  /// required fields. This fail-fast approach prevents null-pointer exceptions
  /// deeper in the application.
  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    try {
      return VehicleDto(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        status: json['status'] as String,
      );
    } catch (_) {
      throw const ParseException('Invalid vehicle response shape');
    }
  }

  /// Transforms this Data Transfer Object into a pure [Vehicle] domain entity.
  ///
  /// **Business Rule Implementation:**
  /// The backend might introduce new status strings over time. To protect the UI
  /// and Domain from unknown states, this method acts as an Anti-Corruption Layer.
  /// It strictly maps known statuses ('available', 'inUse') to the domain enum.
  /// Any unrecognized or unhandled status gracefully defaults to
  /// [VehicleStatus.maintenance], ensuring the UI never displays an unsafe or
  /// falsely operational state.
  Vehicle toDomain() => Vehicle(
    id: id,
    name: name,
    category: category,
    status: switch (status) {
      'available' => VehicleStatus.available,
      'inUse' => VehicleStatus.inUse,
      _ => VehicleStatus.maintenance,
    },
  );
}