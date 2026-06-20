import '../../../shared/domain/entities/models.dart';
import '../../../shared/infrastructure/network/app_exception.dart';

class SignInResponseDto {
  const SignInResponseDto({
    required this.workerId,
    required this.fullName,
    required this.role,
    required this.token,
    this.driverId,
  });

  final String workerId;
  final String fullName;
  final String role;
  final String token;
  final int? driverId;

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

  SessionUser toDomain() => SessionUser(
        workerId: workerId,
        fullName: fullName,
        role: role == 'supervisor' ? UserRole.supervisor : UserRole.operator,
        driverId: driverId,
      );
}