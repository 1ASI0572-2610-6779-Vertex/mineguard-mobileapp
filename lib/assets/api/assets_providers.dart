import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/providers.dart';
import '../domain/interfaces/vehicle_repository.dart';
import '../infrastructure/data_sources/vehicle_remote_data_source.dart';
import '../infrastructure/repositories/vehicle_repository_impl.dart';

/// Provides the remote data source for vehicle-related API calls.
///
/// This provider is kept private (`_`) to enforce encapsulation, ensuring that
/// the presentation layer (UI) cannot access the data source directly, thereby
/// preventing developers from bypassing the repository layer. It depends on the
/// [dioProvider] for handling HTTP network requests.
final _vehicleDataSourceProvider = Provider<VehicleRemoteDataSource>(
      (ref) => VehicleRemoteDataSource(ref.watch(dioProvider)),
);

/// Provides the concrete implementation of [VehicleRepository].
///
/// This is the primary provider exposed to the presentation layer and use cases.
/// It injects the internal [_vehicleDataSourceProvider] into [VehicleRepositoryImpl].
/// By returning the abstract interface [VehicleRepository], it strictly adheres to
/// the Dependency Inversion Principle (the 'D' in SOLID), making the system highly
/// testable and scalable.
final vehicleRepositoryProvider = Provider<VehicleRepository>(
      (ref) => VehicleRepositoryImpl(ref.watch(_vehicleDataSourceProvider)),
);