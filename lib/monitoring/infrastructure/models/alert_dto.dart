import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

class AlertDto {
  const AlertDto({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.elapsedLabel,
    this.primaryAction,
  });

  final String id;
  final String kind;
  final String title;
  final String description;
  final String elapsedLabel;
  final String? primaryAction;

  factory AlertDto.fromJson(Map<String, dynamic> json) {
    try {
      return AlertDto(
        id: json['id'] as String,
        kind: json['kind'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        elapsedLabel: json['elapsedLabel'] as String,
        primaryAction: json['primaryAction'] as String?,
      );
    } catch (_) {
      throw const ParseException('Invalid alert response shape');
    }
  }

  SafetyAlert toDomain() => SafetyAlert(
        id: id,
        kind: switch (kind) {
          'panic' => AlertKind.panic,
          'collisionRisk' => AlertKind.collisionRisk,
          _ => AlertKind.fatigue,
        },
        title: title,
        description: description,
        elapsedLabel: elapsedLabel,
        primaryAction: primaryAction,
      );
}
