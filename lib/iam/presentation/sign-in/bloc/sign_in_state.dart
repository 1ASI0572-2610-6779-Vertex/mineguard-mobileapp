import 'package:equatable/equatable.dart';

// Using an explicit idle state (not just "loading"/"done") so the screen can
// tell "never submitted" apart from "just succeeded" via the bloc listener's
// previous-state check.
enum SignInStatus { initial, loading, success, failure }

class SignInState extends Equatable {
  const SignInState({
    this.status = SignInStatus.initial,
    this.errorMessage,
  });

  final SignInStatus status;
  final String? errorMessage;

  SignInState copyWith({
    SignInStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SignInState(
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, errorMessage];
}
