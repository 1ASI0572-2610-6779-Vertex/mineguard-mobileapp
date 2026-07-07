import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  const ProfileState({this.signingOut = false});

  final bool signingOut;

  ProfileState copyWith({bool? signingOut}) =>
      ProfileState(signingOut: signingOut ?? this.signingOut);

  @override
  List<Object?> get props => [signingOut];
}
