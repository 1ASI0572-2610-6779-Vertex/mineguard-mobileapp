/// Sealed hierarchy maps every network failure to a typed contract.
/// Callers pattern-match instead of catching dynamic exceptions —
/// this forces explicit error handling at compile time.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

/// 401 — token expired or missing. Trigger re-login flow.
final class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired. Please sign in again.');
}

/// 4xx client errors (400, 404, 422 …) with the server's message.
final class ClientException extends AppException {
  const ClientException(super.message, {required this.statusCode});
  final int statusCode;
}

/// 5xx or unexpected server-side failures.
final class ServerException extends AppException {
  const ServerException(super.message);
}

/// No connectivity or connection timeout.
final class NetworkException extends AppException {
  const NetworkException() : super('No internet connection. Check your network.');
}

/// JSON shape did not match the expected model.
final class ParseException extends AppException {
  const ParseException(super.message);
}
