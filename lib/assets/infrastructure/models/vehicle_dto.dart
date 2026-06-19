import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

class VehicleDto {
  const VehicleDto({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
  });

  final String id;
  final String name;
  final String category;
  final String status;

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

  /// The backend may send many status strings. The business rule states
  /// the UI only cares about three; everything else is treated as maintenance
  /// to avoid silently showing an incorrect operational state.
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
