import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/providers.dart';
import '../domain/interfaces/performance_repository.dart';
import '../infrastructure/data_sources/performance_remote_data_source.dart';
import '../infrastructure/repositories/performance_repository_impl.dart';

/// Centraliza la inyección de dependencias del bounded context `analytics`.
///
/// Este archivo conecta la fuente remota con la implementación del repositorio
/// para exponer una única dependencia consumible desde la capa de presentación.
final _performanceDataSourceProvider = Provider<PerformanceRemoteDataSource>(
  (ref) => PerformanceRemoteDataSource(ref.watch(dioProvider)),
);

/// Provee el contrato de dominio para obtener las métricas de desempeño.
final performanceRepositoryProvider = Provider<PerformanceRepository>(
  (ref) => PerformanceRepositoryImpl(ref.watch(_performanceDataSourceProvider)),
);
