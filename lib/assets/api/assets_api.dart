import '../../injections.dart';
import '../presentation/vehicle-selection/bloc/vehicle_selection_bloc.dart';

/// Public cross-context boundary for `assets`.
class AssetsApi {
  /// Discards the cached [VehicleSelectionBloc] singleton so the next screen
  /// mount starts fresh — called on logout to avoid leaking one driver's
  /// selected vehicle into the next driver's session.
  void resetSelectionState() =>
      serviceLocator.resetLazySingleton<VehicleSelectionBloc>();
}
