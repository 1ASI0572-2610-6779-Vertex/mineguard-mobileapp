import 'package:dio/dio.dart';
import 'app_exception.dart';
import 'token_storage.dart';

/// Central Dio factory.
///
/// Two interceptors, one responsibility each:
///   1. [_AuthInterceptor]  — reads the JWT from secure storage and injects
///      the Authorization header on every request. On 401 it clears the token
///      and rethrows [UnauthorizedException] so the auth flow can redirect.
///   2. [_ErrorInterceptor] — normalises Dio errors into [AppException] subtypes
///      so repositories never deal with raw DioException.
class DioClient {
  DioClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
  }) : _dio = _build(baseUrl, tokenStorage);

  final Dio _dio;

  Dio get instance => _dio;

  static Dio _build(String baseUrl, TokenStorage tokenStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Render free-tier instance spins down when idle and can take up to
        // ~140s to cold-boot on the next request — timeouts are sized to
        // survive that instead of failing on the first request after idle.
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(tokenStorage),
      _ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token rejected by the server — clear it so the app forces re-login.
      await _tokenStorage.delete();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(),
          type: DioExceptionType.badResponse,
          response: err.response,
        ),
      );
      return;
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        const NetworkException(),
      DioExceptionType.badResponse => _fromResponse(err),
      _ => err.error is AppException
          ? err.error as AppException
          : ServerException(err.message ?? 'Unknown error'),
    };

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appError,
        type: err.type,
        response: err.response,
      ),
    );
  }

  AppException _fromResponse(DioException err) {
    final status = err.response?.statusCode ?? 0;
    final body = err.response?.data;
    final message = (body is Map ? body['message'] as String? : null) ?? 'Request failed';

    if (status == 401) return const UnauthorizedException();
    if (status >= 400 && status < 500) return ClientException(message, statusCode: status);
    return ServerException(message);
  }
}
