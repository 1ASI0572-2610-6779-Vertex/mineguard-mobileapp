import 'package:dio/dio.dart';
import '../models/sign_in_response_dto.dart';

/// Data Source encargado de comunicarse con el API de autenticación.
class AuthRemoteDataSource {

  /// Cliente HTTP utilizado para realizar las peticiones.
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Inicia sesión enviando las credenciales del trabajador.
  ///
  /// [workerId] : Identificador del trabajador.
  /// [password] : Contraseña del usuario.
  ///
  /// Retorna un objeto [SignInResponseDto] con la información
  /// devuelta por el servidor (token, datos del usuario, etc.).
  Future<SignInResponseDto> signIn({
    required String workerId,
    required String password,
  }) async {

    // Realiza una petición POST al endpoint de login móvil.
    final response = await _dio.post<Map<String, dynamic>>(
      '/mobile-sessions',
      data: {
        'workerId': workerId,
        'password': password,
      },
    );

    // Convierte la respuesta JSON en un DTO y lo retorna.
    return SignInResponseDto.fromJson(response.data!);
  }
}