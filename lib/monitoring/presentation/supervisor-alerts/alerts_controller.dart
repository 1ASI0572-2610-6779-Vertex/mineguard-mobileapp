import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_iot/monitoring/api/monitoring_providers.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';

class AlertsController extends AsyncNotifier<List<SafetyAlert>> {
  @override
  Future<List<SafetyAlert>> build() {
    return ref.read(alertRepositoryProvider).getAlerts();
  }

  Future<void> markReviewed(String alertId) async {
    await ref.read(alertRepositoryProvider).submitAlertAction(alertId);
    state.whenData((alerts) {
      state = AsyncData(alerts.where((a) => a.id != alertId).toList());
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(alertRepositoryProvider).getAlerts(),
    );
  }
}

final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, List<SafetyAlert>>(
  AlertsController.new,
);
