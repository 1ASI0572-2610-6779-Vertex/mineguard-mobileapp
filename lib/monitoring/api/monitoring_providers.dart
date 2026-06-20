import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/providers.dart';
import '../domain/interfaces/alert_repository.dart';
import '../infrastructure/data_sources/alert_remote_data_source.dart';
import '../infrastructure/repositories/alert_repository_impl.dart';

final _alertDataSourceProvider = Provider<AlertRemoteDataSource>(
  (ref) => AlertRemoteDataSource(ref.watch(dioProvider)),
);

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => AlertRepositoryImpl(ref.watch(_alertDataSourceProvider)),
);
