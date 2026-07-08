import 'package:equatable/equatable.dart';

enum AlertKind { panic, collisionRisk, fatigue }

class SafetyAlert extends Equatable {
  final String id;
  final AlertKind kind;
  final String title;
  final String description;

  /// Compact "time since occurrence" label (e.g. `5m`, `2h`, `1d`) derived
  /// from the backend `occurredAt` timestamp.
  final String elapsedLabel;

  /// Whether the alert has already been resolved / dismissed. The default
  /// mobile `GET /alerts` returns only unresolved alerts, so this is normally
  /// false; it drives whether the "mark as reviewed" action is offered.
  final bool resolved;

  const SafetyAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.elapsedLabel,
    this.resolved = false,
  });

  @override
  List<Object?> get props =>
      [id, kind, title, description, elapsedLabel, resolved];
}