import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_iot/shared/application/session_cubit.dart';
import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/bootstrap/presentation/operator-home/operator_home_screen.dart';
import 'package:mobile_iot/monitoring/presentation/supervisor-alerts/supervisor_alerts_screen.dart';
import '../../../injections.dart';
import 'bloc/bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workerIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _workerIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<SignInBloc>().add(SignInSubmitted(
          workerId: _workerIdCtrl.text.trim(),
          password: _passwordCtrl.text,
        ));
  }

  void _goToHome(BuildContext context) {
    final user = context.read<SessionCubit>().state;
    if (user == null) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => user.isSupervisor
            ? const SupervisorAlertsScreen()
            : OperatorHomeScreen(user: user),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (_) => serviceLocator<SignInBloc>(),
      child: BlocListener<SignInBloc, SignInState>(
        // Only navigate on the loading→success transition, so the initial
        // idle state never triggers a spurious navigation.
        listenWhen: (previous, current) =>
            previous.status == SignInStatus.loading &&
            current.status == SignInStatus.success,
        listener: (context, state) => _goToHome(context),
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: AppColors.backgroundMuted,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Logo(),
                          const SizedBox(height: 28),
                          const Center(
                            child: Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Enter your ID and password to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const _FieldLabel('WORKER ID'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _workerIdCtrl,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'E.g. 8492-A',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your ID'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('PASSWORD'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Enter your password'
                                : null,
                          ),
                          BlocBuilder<SignInBloc, SignInState>(
                            builder: (context, state) {
                              if (state.status != SignInStatus.failure ||
                                  state.errorMessage == null) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  const SizedBox(height: 14),
                                  _ErrorBanner(message: state.errorMessage!),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          BlocBuilder<SignInBloc, SignInState>(
                            builder: (context, state) {
                              final isLoading =
                                  state.status == SignInStatus.loading;
                              return ElevatedButton(
                                onPressed:
                                    isLoading ? null : () => _submit(context),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Sign In'),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, size: 18),
                                        ],
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 32),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
