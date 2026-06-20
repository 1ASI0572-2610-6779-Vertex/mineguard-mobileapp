import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_iot/iam/api/iam_providers.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';

// Using Notifier<AsyncValue<void>> instead of AsyncNotifier<void> so the
// initial state is explicitly "idle" (AsyncData) and the view can distinguish
// between "never submitted" and "just succeeded" by checking the previous
// state inside ref.listen.
class SignInController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({
    required String workerId,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signIn(
            workerId: workerId,
            password: password,
          );
      ref.read(sessionProvider.notifier).state = user;
    });
  }

  void reset() => state = const AsyncData(null);
}

final signInControllerProvider =
    NotifierProvider<SignInController, AsyncValue<void>>(
  SignInController.new,
);
