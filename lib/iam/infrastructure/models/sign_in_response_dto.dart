import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

class SignInResponseDto {
  const SignInResponseDto({
    required this.workerId,
    required this.fullName,
    required this.role,
    required this.token,
  });

  final String workerId;
  final String fullName;
  final String role;
  final String token;

  factory SignInResponseDto.fromJson(Map<String, dynamic> json) {
    try {
      return SignInResponseDto(
        workerId: json['workerId'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        token: json['token'] as String,
      );
    } catch (_) {
      throw const ParseException('Invalid sign-in response shape');
    }
  }

  /// Maps the raw role string to the typed domain enum.
  /// Unknown roles default to [UserRole.operator] — least-privilege principle.
  SessionUser toDomain() => SessionUser(
        workerId: workerId,
        fullName: fullName,
        role: role == 'supervisor' ? UserRole.supervisor : UserRole.operator,
      );
}
