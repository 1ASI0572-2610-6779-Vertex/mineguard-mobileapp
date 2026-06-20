import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/providers.dart';
import '../domain/interfaces/vehicle_repository.dart';
import '../infrastructure/data_sources/vehicle_remote_data_source.dart';
import '../infrastructure/repositories/vehicle_repository_impl.dart';

final _vehicleDataSourceProvider = Provider<VehicleRemoteDataSource>(
  (ref) => VehicleRemoteDataSource(ref.watch(dioProvider)),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepositoryImpl(ref.watch(_vehicleDataSourceProvider)),
);
