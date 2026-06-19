import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/providers.dart';
import '../domain/interfaces/performance_repository.dart';
import '../infrastructure/data_sources/performance_remote_data_source.dart';
import '../infrastructure/repositories/performance_repository_impl.dart';

final _performanceDataSourceProvider = Provider<PerformanceRemoteDataSource>(
  (ref) => PerformanceRemoteDataSource(ref.watch(dioProvider)),
);

final performanceRepositoryProvider = Provider<PerformanceRepository>(
  (ref) => PerformanceRepositoryImpl(ref.watch(_performanceDataSourceProvider)),
);
