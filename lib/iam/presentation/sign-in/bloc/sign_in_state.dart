import 'package:equatable/equatable.dart';
import '../../../domain/logic/sign_in_error_mapper.dart';

// Using an explicit idle state (not just "loading"/"done") so the screen can
// tell "never submitted" apart from "just succeeded" via the bloc listener's
// previous-state check.
enum SignInStatus { initial, loading, success, failure }

class SignInState extends Equatable {
  const SignInState({
    this.status = SignInStatus.initial,
    this.errorReason,
  });

  final SignInStatus status;
  final SignInErrorReason? errorReason;

  SignInState copyWith({
    SignInStatus? status,
    SignInErrorReason? errorReason,
    bool clearError = false,
  }) =>
      SignInState(
        status: status ?? this.status,
        errorReason: clearError ? null : (errorReason ?? this.errorReason),
      );

  @override
  List<Object?> get props => [status, errorReason];
}
