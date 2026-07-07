import 'package:equatable/equatable.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => [];
}

class SignInSubmitted extends SignInEvent {
  const SignInSubmitted({required this.workerId, required this.password});

  final String workerId;
  final String password;

  @override
  List<Object?> get props => [workerId, password];
}
