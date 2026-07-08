import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../analytics/api/analytics_api.dart';
import '../../../../assets/api/assets_api.dart';
import '../../../../iam/api/iam_api.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required IamApi iamApi,
    required AssetsApi assetsApi,
    required AnalyticsApi analyticsApi,
  })  : _iamApi = iamApi,
        _assetsApi = assetsApi,
        _analyticsApi = analyticsApi,
        super(const ProfileState());

  final IamApi _iamApi;
  final AssetsApi _assetsApi;
  final AnalyticsApi _analyticsApi;

  /// Signs out and resets the other bounded contexts' cached tab state —
  /// otherwise the next driver to sign in on the same running app would
  /// still see the previous driver's assigned vehicle / performance stats.
  Future<void> signOut() async {
    emit(state.copyWith(signingOut: true));
    await _iamApi.signOut();
    _assetsApi.resetSelectionState();
    _analyticsApi.resetPerformanceState();
    emit(state.copyWith(signingOut: false));
  }

  /// Changes the signed-in driver's password via `PATCH /users/me/password`.
  /// [newPassword] must be at least 8 characters (enforced by the backend and
  /// validated in the UI before this is called).
  Future<void> changePassword(String newPassword) async {
    emit(state.copyWith(
      changingPassword: true,
      passwordChanged: false,
      clearPasswordError: true,
    ));
    try {
      await _iamApi.changePassword(newPassword: newPassword);
      emit(state.copyWith(changingPassword: false, passwordChanged: true));
    } catch (e) {
      emit(state.copyWith(changingPassword: false, passwordError: e));
    }
  }
}
