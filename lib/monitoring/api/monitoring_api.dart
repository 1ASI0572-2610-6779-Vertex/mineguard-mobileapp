import '../../injections.dart';
import '../application/monitoring_facade_service.dart';
import '../domain/entities/safety_alert.dart';

/// Public cross-context boundary for `monitoring`.
class MonitoringApi {
  final MonitoringFacadeService _facade =
      serviceLocator<MonitoringFacadeService>();

  Future<List<SafetyAlert>> getAlerts() => _facade.getAlerts();
}
