import 'package:dio/dio.dart';
import '../models/sign_in_response_dto.dart';

/// Data source responsible for talking to the authentication API.
class AuthRemoteDataSource {

  /// HTTP client used to perform requests.
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Signs in by sending the worker's credentials.
  ///
  /// [workerId] : the worker's identifier.
  /// [password] : the user's password.
  ///
  /// Returns a [SignInResponseDto] with the data returned by the server
  /// (token, user info, etc.).
  Future<SignInResponseDto> signIn({
    required String workerId,
    required String password,
  }) async {

    // POST to the mobile login endpoint.
    final response = await _dio.post<Map<String, dynamic>>(
      '/mobile-sessions',
      data: {
        'workerId': workerId,
        'password': password,
      },
    );

    // Parse the JSON response into a DTO and return it.
    return SignInResponseDto.fromJson(response.data!);
  }

  /// Changes the authenticated user's password.
  ///
  /// Maps to `PATCH /users/me/password` — the JWT (injected by the auth
  /// interceptor) is the proof of identity, so only the new password travels
  /// in the body. The backend enforces a minimum of 8 characters.
  Future<void> changePassword({required String newPassword}) async {
    await _dio.patch<void>(
      '/users/me/password',
      data: {'newPassword': newPassword},
    );
  }
}
