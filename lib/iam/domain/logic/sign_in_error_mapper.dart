import '../../../shared/infrastructure/network/app_exception.dart';

/// Maps a sign-in failure to a user-facing message.
///
/// Pure function — no Flutter/BuildContext dependency — so it's reusable
/// from the bloc and unit-testable in isolation.
String mapSignInError(Object? error) {
  if (error is UnimplementedError) return 'Feature not implemented';
  if (error is UnauthorizedException || error is ClientException) {
    return 'Incorrect ID or password';
  }
  if (error is NetworkException) {
    return 'No connection to the server. Check your network';
  }
  return 'Sign-in failed. Please try again';
}
