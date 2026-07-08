import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.signingOut = false,
    this.changingPassword = false,
    this.passwordChanged = false,
    this.passwordError,
  });

  final bool signingOut;
  final bool changingPassword;

  /// Set true for one emission after a successful password change so the UI
  /// can show a confirmation; reset on the next attempt.
  final bool passwordChanged;
  final Object? passwordError;

  ProfileState copyWith({
    bool? signingOut,
    bool? changingPassword,
    bool? passwordChanged,
    Object? passwordError,
    bool clearPasswordError = false,
  }) =>
      ProfileState(
        signingOut: signingOut ?? this.signingOut,
        changingPassword: changingPassword ?? this.changingPassword,
        passwordChanged: passwordChanged ?? this.passwordChanged,
        passwordError:
            clearPasswordError ? null : (passwordError ?? this.passwordError),
      );

  @override
  List<Object?> get props =>
      [signingOut, changingPassword, passwordChanged, passwordError];
}