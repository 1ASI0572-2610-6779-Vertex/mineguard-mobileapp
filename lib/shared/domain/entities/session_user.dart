import 'package:equatable/equatable.dart';

enum UserRole { operator, supervisor }

/// Shared-kernel value type: the identity of the signed-in user.
///
/// Owned by `shared` rather than `iam` because every bounded context reads
/// it (assets/analytics need `driverId`, all of them need it for display and
/// logout) — `iam` owns the authentication *process*, not this value type.
class SessionUser extends Equatable {
  final String workerId;
  final String fullName;
  final UserRole role;
  final int? driverId;

  const SessionUser({
    required this.workerId,
    required this.fullName,
    required this.role,
    this.driverId,
  });

  bool get isOperator => role == UserRole.operator;
  bool get isSupervisor => role == UserRole.supervisor;

  @override
  List<Object?> get props => [workerId, fullName, role, driverId];
}
