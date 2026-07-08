import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/session_user.dart';

/// Cross-cutting "current session" state, provided once at the app root.
///
/// This is the one deliberate exception to "no shared mutable state": every
/// bounded context needs read access to the signed-in user (driverId, role,
/// display name), so it's registered as a single lazy singleton in get_it and
/// exposed to the widget tree via `BlocProvider.value` in main.dart.
class SessionCubit extends Cubit<SessionUser?> {
  SessionCubit() : super(null);

  void setSession(SessionUser user) => emit(user);

  void clear() => emit(null);
}
