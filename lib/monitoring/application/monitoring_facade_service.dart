import '../domain/entities/safety_alert.dart';
import '../domain/interfaces/alert_repository.dart';

class MonitoringFacadeService {
  const MonitoringFacadeService({required this.repository});

  final AlertRepository repository;

  Future<List<SafetyAlert>> getAlerts() => repository.getAlerts();

  Future<void> submitAlertAction(String alertId) =>
      repository.submitAlertAction(alertId);
}
