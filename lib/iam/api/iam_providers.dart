import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/providers.dart';
import '../domain/interfaces/auth_repository.dart';
import '../infrastructure/data_sources/auth_remote_data_source.dart';
import '../infrastructure/repositories/auth_repository_impl.dart';

final _authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(_authDataSourceProvider),
    ref.watch(tokenStorageProvider),
  ),
);
