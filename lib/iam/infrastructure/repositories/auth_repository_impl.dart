import 'package:dio/dio.dart';
import '../../../shared/domain/entities/session_user.dart';
import '../../../shared/infrastructure/network/app_exception.dart';
import '../../../shared/infrastructure/network/token_storage.dart';
import '../../domain/interfaces/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

/// Authentication repository implementation.
///
/// Acts as a bridge between the domain layer and the remote data source,
/// while also managing token persistence.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource, this._tokenStorage);

  /// Remote data source responsible for API authentication requests.
  final AuthRemoteDataSource _dataSource;

  /// Service used to store and delete the authentication token.
  final TokenStorage _tokenStorage;

  @override
  Future<SessionUser> signIn({
    required String workerId,
    required String password,
  }) async {
    try {
      // Sends the authentication request to the backend.
      final dto = await _dataSource.signIn(
        workerId: workerId,
        password: password,
      );

      // Stores the token locally so future requests are authenticated.
      await _tokenStorage.save(dto.token);

      // Converts the DTO into a domain entity and returns it.
      return dto.toDomain();
    } on DioException catch (e) {
      // Re-throws known application exceptions or wraps
      // unexpected errors in a generic server exception.
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? '');
    }
  }

  @override
  Future<void> signOut() =>
      // Removes the stored token to end the session.
  _tokenStorage.delete();

  @override
  Future<void> changePassword({required String newPassword}) async {
    try {
      await _dataSource.changePassword(newPassword: newPassword);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : ServerException(e.message ?? '');
    }
  }
}
