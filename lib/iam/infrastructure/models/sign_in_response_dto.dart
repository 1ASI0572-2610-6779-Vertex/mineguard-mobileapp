import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

/// DTO que representa la respuesta recibida desde el API
/// después de un inicio de sesión exitoso.
class SignInResponseDto {
  const SignInResponseDto({
    required this.workerId,
    required this.fullName,
    required this.role,
    required this.token,
    this.driverId,
  });

  /// Identificador del trabajador.
  final String workerId;

  /// Nombre completo del usuario autenticado.
  final String fullName;

  /// Rol asignado al usuario (operator, supervisor, etc.).
  final String role;

  /// Token JWT utilizado para las solicitudes autenticadas.
  final String token;

  /// Identificador del conductor asociado (opcional).
  final int? driverId;

  /// Construye el DTO a partir de la respuesta JSON del API.
  ///
  /// Lanza una [ParseException] si la estructura de la respuesta
  /// no coincide con la esperada.
  factory SignInResponseDto.fromJson(Map<String, dynamic> json) {
    try {
      return SignInResponseDto(
        workerId: json['workerId'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        token: json['token'] as String,
        driverId: json['driverId'] as int?,
      );
    } catch (_) {
      throw const ParseException('Invalid sign-in response shape');
    }
  }

  /// Convierte el DTO en una entidad de dominio [SessionUser].
  ///
  /// Realiza también la conversión del rol recibido desde el API
  /// al enum correspondiente de la aplicación.
  SessionUser toDomain() => SessionUser(
    workerId: workerId,
    fullName: fullName,
    role: role == 'supervisor'
        ? UserRole.supervisor
        : UserRole.operator,
    driverId: driverId,
  );
}