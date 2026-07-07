import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'analytics/application/analytics_facade_service.dart';
import 'analytics/domain/interfaces/performance_repository.dart';
import 'analytics/infrastructure/data_sources/performance_remote_data_source.dart';
import 'analytics/infrastructure/repositories/performance_repository_impl.dart';
import 'analytics/presentation/performance/bloc/performance_bloc.dart';
import 'assets/application/assets_facade_service.dart';
import 'assets/domain/interfaces/vehicle_repository.dart';
import 'assets/infrastructure/data_sources/vehicle_remote_data_source.dart';
import 'assets/infrastructure/repositories/vehicle_repository_impl.dart';
import 'assets/presentation/vehicle-selection/bloc/vehicle_selection_bloc.dart';
import 'iam/application/iam_facade_service.dart';
import 'iam/domain/interfaces/auth_repository.dart';
import 'iam/infrastructure/data_sources/auth_remote_data_source.dart';
import 'iam/infrastructure/repositories/auth_repository_impl.dart';
import 'iam/presentation/sign-in/bloc/sign_in_bloc.dart';
import 'monitoring/application/monitoring_facade_service.dart';
import 'monitoring/domain/interfaces/alert_repository.dart';
import 'monitoring/infrastructure/data_sources/alert_remote_data_source.dart';
import 'monitoring/infrastructure/repositories/alert_repository_impl.dart';
import 'monitoring/presentation/supervisor-alerts/bloc/supervisor_alerts_bloc.dart';
import 'analytics/api/analytics_api.dart';
import 'assets/api/assets_api.dart';
import 'iam/api/iam_api.dart';
import 'profile/presentation/settings/bloc/profile_cubit.dart';
import 'shared/application/locale_cubit.dart';
import 'shared/application/session_cubit.dart';
import 'shared/infrastructure/network/dio_client.dart';
import 'shared/infrastructure/network/token_storage.dart';
import 'shared/infrastructure/storage/locale_preference_storage.dart';

final serviceLocator = GetIt.instance;

const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://mineguard-webservice.onrender.com/api/v1',
);

/// Root DI wiring. One `<context>Dependencies()` function per bounded
/// context, registered top-to-bottom in dependency order.
Future<void> init() async {
  sharedDependencies();
  iamDependencies();
  assetsDependencies();
  monitoringDependencies();
  analyticsDependencies();
  profileDependencies();
}

void sharedDependencies() {
  serviceLocator.registerLazySingleton(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  serviceLocator.registerLazySingleton(
    () => TokenStorage(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<Dio>(
    () => DioClient(baseUrl: _kBaseUrl, tokenStorage: serviceLocator()).instance,
  );
  serviceLocator.registerLazySingleton(() => SessionCubit());
  serviceLocator.registerLazySingleton(
    () => LocalePreferenceStorage(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(() => LocaleCubit(serviceLocator()));
}

void iamDependencies() {
  // Presentation
  serviceLocator.registerFactory(
    () => SignInBloc(
      iamFacade: serviceLocator(),
      sessionCubit: serviceLocator(),
    ),
  );
  // Application
  serviceLocator.registerLazySingleton(
    () => IamFacadeService(
      repository: serviceLocator(),
      sessionCubit: serviceLocator(),
    ),
  );
  // Infrastructure
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => AuthRemoteDataSource(serviceLocator()),
  );
}

void assetsDependencies() {
  // Presentation — lazy singleton (not factory) so vehicle-selection state
  // survives switching bottom-nav tabs; reset explicitly on logout via
  // AssetsApi.resetSelectionState().
  serviceLocator.registerLazySingleton(
    () => VehicleSelectionBloc(
      assetsFacade: serviceLocator(),
      sessionCubit: serviceLocator(),
    ),
  );
  // Application
  serviceLocator.registerLazySingleton(
    () => AssetsFacadeService(repository: serviceLocator()),
  );
  // Infrastructure
  serviceLocator.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => VehicleRemoteDataSource(serviceLocator()),
  );
}

void monitoringDependencies() {
  // Presentation — factory: full-screen, once-per-session feature (not a
  // tab), fresh instance each mount is fine.
  serviceLocator.registerFactory(
    () => SupervisorAlertsBloc(monitoringFacade: serviceLocator()),
  );
  // Application
  serviceLocator.registerLazySingleton(
    () => MonitoringFacadeService(repository: serviceLocator()),
  );
  // Infrastructure
  serviceLocator.registerLazySingleton<AlertRepository>(
    () => AlertRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => AlertRemoteDataSource(serviceLocator()),
  );
}

void analyticsDependencies() {
  // Presentation — lazy singleton (not factory), same reasoning as
  // VehicleSelectionBloc: survives bottom-nav tab switches, reset explicitly
  // on logout via AnalyticsApi.resetPerformanceState().
  serviceLocator.registerLazySingleton(
    () => PerformanceBloc(
      analyticsFacade: serviceLocator(),
      sessionCubit: serviceLocator(),
    ),
  );
  // Application
  serviceLocator.registerLazySingleton(
    () => AnalyticsFacadeService(repository: serviceLocator()),
  );
  // Infrastructure
  serviceLocator.registerLazySingleton<PerformanceRepository>(
    () => PerformanceRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => PerformanceRemoteDataSource(serviceLocator()),
  );
}

void profileDependencies() {
  // profile has no facade/repository of its own — ProfileCubit only
  // orchestrates cross-context calls via the other contexts' Api classes.
  serviceLocator.registerFactory(
    () => ProfileCubit(
      iamApi: IamApi(),
      assetsApi: AssetsApi(),
      analyticsApi: AnalyticsApi(),
    ),
  );
}
