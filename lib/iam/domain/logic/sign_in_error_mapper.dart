import '../../../shared/infrastructure/network/app_exception.dart';

enum SignInErrorReason { invalidCredentials, network, unknown }

/// Maps a sign-in failure to a typed reason.
///
/// Pure function — no Flutter/BuildContext dependency — the presentation
/// layer maps the reason to a localized string at render time, so this stays
/// unit-testable in isolation and independent of the chosen locale.
SignInErrorReason mapSignInErrorReason(Object? error) {
  if (error is UnauthorizedException || error is ClientException) {
    return SignInErrorReason.invalidCredentials;
  }
  if (error is NetworkException) {
    return SignInErrorReason.network;
  }
  return SignInErrorReason.unknown;
}
