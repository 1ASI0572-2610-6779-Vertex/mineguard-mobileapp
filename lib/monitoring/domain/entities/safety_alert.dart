import 'package:equatable/equatable.dart';

enum AlertKind { panic, collisionRisk, fatigue }

class SafetyAlert extends Equatable {
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

  @override
  List<Object?> get props =>
      [id, kind, title, description, elapsedLabel, primaryAction];
}
