import 'package:dio/dio.dart';
import '../models/sign_in_response_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SignInResponseDto> signIn({
    required String workerId,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/sign-in',
      data: {'workerId': workerId, 'password': password},
    );
    return SignInResponseDto.fromJson(response.data!);
  }
}
