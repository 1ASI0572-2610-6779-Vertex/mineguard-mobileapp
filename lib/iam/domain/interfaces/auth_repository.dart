import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

/// Contract the application layer talks to.
/// The abstract boundary means we can swap in a mock for tests
/// without touching a single widget or use-case.
abstract interface class AuthRepository {
  /// Authenticates the worker and persists the JWT internally.
  /// Returns [SessionUser] on success or throws [AppException].
  Future<SessionUser> signIn({
    required String workerId,
    required String password,
  });

  /// Removes the stored token (logout).
  Future<void> signOut();
}
