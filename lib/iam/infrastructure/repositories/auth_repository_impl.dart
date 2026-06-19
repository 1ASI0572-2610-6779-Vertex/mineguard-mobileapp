import 'package:dio/dio.dart';
import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';
import '../../../shared/infrastructure/network/token_storage.dart';
import '../../domain/interfaces/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource, this._tokenStorage);

  final AuthRemoteDataSource _dataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<SessionUser> signIn({
    required String workerId,
    required String password,
  }) async {
    try {
      final dto = await _dataSource.signIn(workerId: workerId, password: password);
      // Persist token before returning so subsequent requests are authenticated.
      await _tokenStorage.save(dto.token);
      return dto.toDomain();
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : ServerException(e.message ?? '');
    }
  }

  @override
  Future<void> signOut() => _tokenStorage.delete();
}
