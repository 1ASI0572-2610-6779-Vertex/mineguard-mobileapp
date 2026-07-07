import '../../shared/application/session_cubit.dart';
import '../../shared/domain/entities/session_user.dart';
import '../domain/interfaces/auth_repository.dart';

/// Orchestrates the iam bounded context: coordinates the auth repository
/// with the app-wide session state. Called by [SignInBloc]/[IamApi], never
/// by presentation code directly.
class IamFacadeService {
  const IamFacadeService({
    required this.repository,
    required this.sessionCubit,
  });

  final AuthRepository repository;
  final SessionCubit sessionCubit;

  Future<SessionUser> signIn({
    required String workerId,
    required String password,
  }) =>
      repository.signIn(workerId: workerId, password: password);

  /// Signs out: clears the stored token and the app-wide session.
  Future<void> signOut() async {
    await repository.signOut();
    sessionCubit.clear();
  }
}
