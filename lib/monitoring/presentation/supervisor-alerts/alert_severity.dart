import 'package:mobile_iot/shared/widgets/app_feedback.dart';

import '../../domain/entities/safety_alert.dart';

/// Presentation mapping from a MineGuard [AlertKind] to the [AppSeverity] that
/// drives the feedback system's color, animation and urgency.
///
/// Lives in the presentation layer (not domain) on purpose: [AppSeverity] is a
/// UI concept, so the domain stays free of any Flutter/presentation coupling.
AppSeverity alertSeverity(AlertKind kind) {
  switch (kind) {
    case AlertKind.panic:
    case AlertKind.collisionRisk:
      return AppSeverity.critical;
    case AlertKind.fatigue:
      return AppSeverity.warning;
  }
}
