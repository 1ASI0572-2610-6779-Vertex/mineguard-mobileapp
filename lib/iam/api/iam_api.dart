import '../../injections.dart';
import '../application/iam_facade_service.dart';

/// Public cross-context boundary for `iam`. Other bounded contexts
/// (e.g. `profile`, `monitoring`) call this instead of reaching into iam's
/// facade/repository/bloc internals directly.
class IamApi {
  final IamFacadeService _facade = serviceLocator<IamFacadeService>();

  Future<void> signOut() => _facade.signOut();

  Future<void> changePassword({required String newPassword}) =>
      _facade.changePassword(newPassword: newPassword);
}
