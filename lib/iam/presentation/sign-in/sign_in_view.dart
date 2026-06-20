import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';
import 'package:mobile_iot/bootstrap/presentation/operator-home/operator_home_view.dart';
import 'package:mobile_iot/monitoring/presentation/supervisor-alerts/supervisor_alerts_view.dart';
import 'sign_in_controller.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(signInControllerProvider.notifier).signIn(
          workerId: _workerIdCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  void _goToHome() {
    final user = ref.read(sessionProvider);
    if (user == null || !mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => user.isSupervisor
            ? const SupervisorAlertsView()
            : OperatorHomeView(user: user),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only navigate when the transition is loading → data, meaning an actual
    // login just completed. Ignores the initial idle AsyncData(null) at startup.
    ref.listen<AsyncValue<void>>(signInControllerProvider, (prev, next) {
      if (prev is AsyncLoading && next is AsyncData) {
        _goToHome();
      }
      // Error is shown inline via the errorMsg below — no snackbar needed.
    });

    final ctrlState = ref.watch(signInControllerProvider);
    final isLoading = ctrlState is AsyncLoading;
    final errorMsg = ctrlState is AsyncError
        ? _friendlyError(ctrlState.error)
        : null;

    return Scaffold(
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
                        'Bienvenido',
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
                        'Ingresa tu ID y contraseña para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _FieldLabel('ID DE TRABAJADOR'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _workerIdCtrl,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Ej. 8492-A',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu ID' : null,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('CONTRASEÑA'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                    ),
                    // Error banner — only visible when state is AsyncError
                    if (errorMsg != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: errorMsg),
                    ],
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Iniciar Sesión'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyError(Object? error) {
    final msg = error?.toString() ?? '';
    if (error is UnimplementedError) return 'Función no implementada';
    if (msg.contains('Session expired') || msg.contains('401')) {
      return 'ID o contraseña incorrectos';
    }
    if (msg.contains('No internet') || msg.contains('NetworkException') ||
        msg.contains('SocketException') || msg.contains('connect')) {
      return 'Sin conexión con el servidor. Verifica tu red';
    }
    if (msg.contains('ClientException')) return 'ID o contraseña incorrectos';
    return 'Error al iniciar sesión. Inténtalo de nuevo';
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
