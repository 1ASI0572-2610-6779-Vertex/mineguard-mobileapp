import '../../../shared/domain/entities/session_user.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

/// DTO representing the API response after a successful sign-in.
class SignInResponseDto {
  const SignInResponseDto({
    required this.workerId,
    required this.fullName,
    required this.role,
    required this.token,
    this.driverId,
  });

  /// The worker's identifier.
  final String workerId;

  /// The authenticated user's full name.
  final String fullName;

  /// The role assigned to the user (operator, supervisor, etc.).
  final String role;

  /// The JWT token used for authenticated requests.
  final String token;

  /// The associated driver identifier (optional).
  final int? driverId;

  /// Builds the DTO from the API's JSON response.
  ///
  /// Throws a [ParseException] if the response shape doesn't match.
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

  /// Converts the DTO into a [SessionUser] domain entity.
  ///
  /// Maps the backend role string to the application's enum. IAM emits roles
  /// in upper-case (`SUPERVISOR`, `DRIVER`, and their `ROLE_`-prefixed
  /// variants), so the match is case-insensitive and substring-based rather
  /// than an exact `== 'supervisor'` (which silently misclassified every
  /// supervisor as an operator). Anything that isn't a supervisor — chiefly
  /// `DRIVER` — is treated as an operator, matching this app's driver-first
  /// scope.
  SessionUser toDomain() => SessionUser(
    workerId: workerId,
    fullName: fullName,
    role: role.toUpperCase().contains('SUPERVISOR')
        ? UserRole.supervisor
        : UserRole.operator,
    driverId: driverId,
  );
}
