import 'package:mobile_iot/shared/domain/entities/models.dart';

/// Datos cruda hardcoded. Pensado para reemplazarse por llamadas a backend.
/// Mantener la API pública (`MockApi.xxx`) estable para que la migración
/// solo cambie la implementación interna.
class MockApi {
  const MockApi._();

  static SessionUser? signIn({required String workerId, required String password}) {
    final id = workerId.trim().toUpperCase();
    if (password.isEmpty) return null;
    if (id == 'OP-8842') {
      return const SessionUser(
        workerId: 'OP-8842',
        fullName: 'Juan Pérez',
        role: UserRole.operator,
      );
    }
    if (id == 'SUP-8842') {
      return const SessionUser(
        workerId: 'SUP-8842',
        fullName: 'Carlos Díaz',
        role: UserRole.supervisor,
      );
    }
    return null;
  }

  static List<Vehicle> vehicles() => const [
        Vehicle(
          id: '12',
          name: 'Camioneta - 12',
          category: 'Vehículo Liviano',
          status: VehicleStatus.available,
        ),
        Vehicle(
          id: '54',
          name: 'Camioneta - 54',
          category: 'Vehículo Liviano',
          status: VehicleStatus.inUse,
        ),
        Vehicle(
          id: '13',
          name: 'Camioneta - 13',
          category: 'Vehículo Liviano',
          status: VehicleStatus.maintenance,
        ),
        Vehicle(
          id: '08',
          name: 'Camioneta - 08',
          category: 'Vehículo Liviano',
          status: VehicleStatus.available,
        ),
        Vehicle(
          id: '21',
          name: 'Camión - 21',
          category: 'Vehículo Pesado',
          status: VehicleStatus.available,
        ),
      ];

  static PerformanceStats performance() => const PerformanceStats(
        safetyScore: 98,
        safetyScoreDelta: 2,
        fatigueAlerts: 0,
        drivingHours: 3.5,
        drivingHoursLimit: 8,
      );

  static List<SafetyAlert> recentAlerts() => const [
        SafetyAlert(
          id: 'a1',
          kind: AlertKind.panic,
          title: 'Botón de Pánico Activado',
          description:
              'Conductor: Luis Gomez (Camioneta - 02) ha reportado una emergencia en Acceso Mina.',
          elapsedLabel: 'Hace 1 min',
          primaryAction: 'Llamar a Cabina',
        ),
        SafetyAlert(
          id: 'a2',
          kind: AlertKind.collisionRisk,
          title: 'Riesgo de Colisión',
          description: 'Camioneta propensa a colisionar en Tramo Norte A',
          elapsedLabel: 'Hace 5 min',
        ),
        SafetyAlert(
          id: 'a3',
          kind: AlertKind.fatigue,
          title: 'Fatiga Detectada',
          description:
              'Carlos Ruiz presenta pulso irregular asociado a somnolencia',
          elapsedLabel: 'Hace 15 min',
          primaryAction: 'Marcar como Revisado',
        ),
      ];
}
