import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_iot/injections.dart';
import 'package:mobile_iot/shared/application/locale_cubit.dart';
import 'package:mobile_iot/shared/infrastructure/storage/locale_preference_storage.dart';
import 'package:mobile_iot/l10n/generated/app_localizations.dart';
import 'package:mobile_iot/monitoring/application/monitoring_facade_service.dart';
import 'package:mobile_iot/monitoring/domain/entities/safety_alert.dart';
import 'package:mobile_iot/monitoring/domain/interfaces/alert_repository.dart';
import 'package:mobile_iot/monitoring/presentation/supervisor-alerts/alert_severity.dart';
import 'package:mobile_iot/monitoring/presentation/supervisor-alerts/bloc/bloc.dart';
import 'package:mobile_iot/monitoring/presentation/supervisor-alerts/supervisor_alerts_screen.dart';
import 'package:mobile_iot/shared/application/session_cubit.dart';
import 'package:mobile_iot/shared/domain/entities/session_user.dart';
import 'package:mobile_iot/shared/widgets/app_feedback.dart';

/// Fake backend the test drives directly: mutate [alerts], then let the
/// screen's background poll pick up the change.
class _FakeAlertRepo implements AlertRepository {
  List<SafetyAlert> alerts = [];

  @override
  Future<List<SafetyAlert>> getAlerts() async => List.of(alerts);

  @override
  Future<void> submitAlertAction(String alertId) async {}
}

SafetyAlert _alert(String id, AlertKind kind, String title) => SafetyAlert(
  id: id,
  kind: kind,
  title: title,
  description: 'desc',
  elapsedLabel: '1m',
);

void main() {
  group('alertSeverity mapping', () {
    test('panic and collisionRisk map to critical', () {
      expect(alertSeverity(AlertKind.panic), AppSeverity.critical);
      expect(alertSeverity(AlertKind.collisionRisk), AppSeverity.critical);
    });

    test('fatigue maps to warning', () {
      expect(alertSeverity(AlertKind.fatigue), AppSeverity.warning);
    });
  });

  group('supervisor screen new-alert toasts', () {
    late _FakeAlertRepo repo;
    late SessionCubit session;

    setUp(() async {
      await serviceLocator.reset();
      repo = _FakeAlertRepo();
      serviceLocator.registerLazySingleton<MonitoringFacadeService>(
        () => MonitoringFacadeService(repository: repo),
      );
      serviceLocator.registerFactory(
        () => SupervisorAlertsBloc(monitoringFacade: serviceLocator()),
      );
      session = SessionCubit()
        ..setSession(
          const SessionUser(
            workerId: 'S-1',
            fullName: 'Sam Supervisor',
            role: UserRole.supervisor,
          ),
        );
    });

    tearDown(() async {
      await serviceLocator.reset();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: session),
              BlocProvider<LocaleCubit>(
                create: (_) =>
                    LocaleCubit(LocalePreferenceStorage(const FlutterSecureStorage())),
              ),
            ],
            child: const SupervisorAlertsScreen(),
          ),
        ),
      );
      // Let initState's initial fetch resolve to a loaded state.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('existing backlog does not toast on first load', (
      tester,
    ) async {
      repo.alerts = [_alert('a1', AlertKind.fatigue, 'Fatigue on Truck 3')];
      await pumpScreen(tester);

      expect(find.byType(SnackBar), findsNothing);

      await tester.pumpWidget(const SizedBox()); // unmount → cancel timers
      await tester.pump();
    });

    testWidgets('a new collision alert auto-fires a critical toast', (
      tester,
    ) async {
      repo.alerts = [_alert('a1', AlertKind.fatigue, 'Fatigue on Truck 3')];
      await pumpScreen(tester);

      // A new collision alert arrives at the backend.
      repo.alerts = [
        ...repo.alerts,
        _alert('a2', AlertKind.collisionRisk, 'Collision risk on Truck 7'),
      ];

      // Advance to the next background poll (20s) and let it resolve + animate.
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(SnackBar), findsOneWidget);
      // Critical severity → carries an explicit dismiss control.
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox()); // unmount → cancel timers
      await tester.pump();
    });

    testWidgets('a new fatigue alert toasts without a forced dismiss control', (
      tester,
    ) async {
      repo.alerts = [_alert('a1', AlertKind.panic, 'Panic on Truck 1')];
      await pumpScreen(tester);

      repo.alerts = [
        ...repo.alerts,
        _alert('a2', AlertKind.fatigue, 'Fatigue on Truck 9'),
      ];

      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SnackBar), findsOneWidget);
      // Warning severity is reviewable — no forced close control.
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
