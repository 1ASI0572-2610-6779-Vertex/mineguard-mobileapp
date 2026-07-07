import '../../../shared/domain/entities/session_user.dart';

/// Pure function: resolves the driverId from the current session, or `null`
/// if there isn't one (e.g. a non-driver user). Replaces the old inline
/// `throw StateError(...)` with a value the bloc can turn into an error
/// state instead of an uncaught exception.
int? resolveDriverIdOrNull(SessionUser? user) => user?.driverId;
