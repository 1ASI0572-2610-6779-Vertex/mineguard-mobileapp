import 'package:equatable/equatable.dart';

enum VehicleStatus { available, inUse, maintenance }

class Vehicle extends Equatable {
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

  @override
  List<Object?> get props => [id, name, category, status];
}
