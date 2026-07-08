import '../../domain/entities/safety_alert.dart';

/// DTO for an alert returned by `GET /alerts`.
///
/// The backend enriches each alert with the driver name, vehicle code and
/// incident description, exposing the fields of `AlertResource` /
/// `MobileAlertResource` (`id`, `type`, `priority`, `status`, `occurredAt`,
/// `title`, `description`, `vehicleCode`, `driverName`). Parsing is
/// **tolerant**: every field is read defensively (id may arrive as a number,
/// optional enrichment fields may be absent) so a minor shape difference
/// degrades gracefully instead of throwing and blanking the whole screen.
class AlertDto {
  const AlertDto({
    required this.id,
    required this.type,
    required this.priority,
    required this.status,
    required this.title,
    required this.description,
    this.driverName,
    this.vehicleCode,
    this.occurredAt,
  });

  final String id;
  final String type;
  final String priority;
  final String status;
  final String title;
  final String description;
  final String? driverName;
  final String? vehicleCode;
  final DateTime? occurredAt;

  factory AlertDto.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v == null ? '' : v.toString();
    final occurredRaw = json['occurredAt'] ?? json['timestamp'];
    return AlertDto(
      id: str(json['id']),
      type: str(json['type'] ?? json['incidentType']),
      priority: str(json['priority'] ?? json['severity']),
      status: str(json['status']),
      title: str(json['title'] ?? json['type'] ?? json['incidentType']),
      description: str(json['description'] ?? json['title']),
      driverName: json['driverName']?.toString(),
      vehicleCode: json['vehicleCode']?.toString(),
      occurredAt:
          occurredRaw == null ? null : DateTime.tryParse(occurredRaw.toString()),
    );
  }

  SafetyAlert toDomain() {
    // Enrich the human-facing subtitle with driver / vehicle when the base
    // description alone doesn't carry them.
    final parts = <String>[
      if (description.isNotEmpty) description,
      if (vehicleCode != null && vehicleCode!.isNotEmpty) vehicleCode!,
      if (driverName != null && driverName!.isNotEmpty) driverName!,
    ];
    return SafetyAlert(
      id: id,
      kind: _deriveKind(type, priority),
      title: title.isEmpty ? type : title,
      description: parts.join(' · '),
      elapsedLabel: _elapsedLabel(occurredAt),
      resolved: status.toLowerCase() == 'resolved' ||
          status.toLowerCase() == 'false_alarm',
    );
  }

  /// Maps the backend incident `type`/`priority` onto the UI's visual buckets.
  /// Proximity/collision/restricted-zone events are the "hard" red bucket;
  /// fatigue and heart-rate events are the "soft" yellow bucket. Unknown types
  /// fall back on priority.
  static AlertKind _deriveKind(String type, String priority) {
    final t = type.toLowerCase();
    if (t.contains('collision') ||
        t.contains('proximity') ||
        t.contains('restricted')) {
      return AlertKind.collisionRisk;
    }
    if (t.contains('fatigue') || t.contains('heart')) {
      return AlertKind.fatigue;
    }
    final p = priority.toLowerCase();
    if (p.contains('critical') || p.contains('high')) {
      return AlertKind.collisionRisk;
    }
    return AlertKind.fatigue;
  }

  static String _elapsedLabel(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.isNegative) return '';
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}