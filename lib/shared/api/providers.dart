import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../infrastructure/network/dio_client.dart';
import '../infrastructure/network/token_storage.dart';

// ── Change this via a build flavor / --dart-define in CI ──────────────────────
const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.mineguard.io/v1',
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

final dioProvider = Provider<Dio>(
  (ref) => DioClient(
    baseUrl: _kBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
  ).instance,
);
