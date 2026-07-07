import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/application/session_cubit.dart';
import '../../../../shared/infrastructure/network/app_exception.dart';
import '../../../application/iam_facade_service.dart';
import '../../../domain/logic/sign_in_error_mapper.dart';
import 'bloc.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc({
    required IamFacadeService iamFacade,
    required SessionCubit sessionCubit,
  })  : _iamFacade = iamFacade,
        _sessionCubit = sessionCubit,
        super(const SignInState()) {
    on<SignInSubmitted>(_onSubmitted);
  }

  final IamFacadeService _iamFacade;
  final SessionCubit _sessionCubit;

  Future<void> _onSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(state.copyWith(status: SignInStatus.loading, clearError: true));
    try {
      final user = await _iamFacade.signIn(
        workerId: event.workerId,
        password: event.password,
      );
      _sessionCubit.setSession(user);
      emit(state.copyWith(status: SignInStatus.success));
    } on AppException catch (e) {
      emit(state.copyWith(
        status: SignInStatus.failure,
        errorReason: mapSignInErrorReason(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SignInStatus.failure,
        errorReason: mapSignInErrorReason(e),
      ));
    }
  }
}
