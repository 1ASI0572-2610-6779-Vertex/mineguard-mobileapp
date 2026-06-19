import '../../../shared/domain/entities/models.dart';

abstract interface class AlertRepository {
  /// Fetches active alerts for the authenticated operator.
  Future<List<SafetyAlert>> getAlerts();

  /// Records that the operator acknowledged / acted on an alert.
  Future<void> submitAlertAction(String alertId);
}
