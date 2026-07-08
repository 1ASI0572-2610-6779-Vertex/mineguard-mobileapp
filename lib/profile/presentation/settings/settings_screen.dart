import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/config/app_theme.dart';
import 'package:mobile_iot/shared/domain/entities/session_user.dart';
import 'package:mobile_iot/shared/widgets/greeting_header.dart';
import 'package:mobile_iot/shared/widgets/language_toggle.dart';
import 'package:mobile_iot/shared/widgets/app_feedback.dart';
import 'package:mobile_iot/shared/widgets/localized_error_message.dart';
import 'package:mobile_iot/iam/presentation/sign-in/sign_in_screen.dart';
import 'package:mobile_iot/l10n/generated/app_localizations.dart';
import '../../../injections.dart';
import 'bloc/bloc.dart';

class SettingsScreen extends StatelessWidget {
  final SessionUser user;
  const SettingsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider<ProfileCubit>(
      create: (_) => serviceLocator<ProfileCubit>(),
      child: Column(
        children: [
          GreetingHeader(user: user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.settingsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (tileContext) => _SettingsTile(
                    title: l10n.settingsUpdatePassword,
                    onTap: () => _showChangePassword(tileContext),
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsTile(
                  title: l10n.settingsZoneManual,
                  onTap: () => _showZoneManual(context),
                ),
                const SizedBox(height: 10),
                _LanguageTile(label: l10n.settingsLanguageLabel),
                const SizedBox(height: 24),
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) => OutlinedButton.icon(
                    onPressed: state.signingOut
                        ? null
                        : () => _confirmLogout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l10n.commonSignOutButton),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      backgroundColor: AppColors.errorSoft,
                      side: BorderSide.none,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    // Captured here so the dialog (mounted on the root navigator, outside this
    // subtree) can still reach the ProfileCubit via BlocProvider.value.
    final cubit = context.read<ProfileCubit>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider<ProfileCubit>.value(
        value: cubit,
        child: const _ChangePasswordDialog(),
      ),
    );
  }

  void _showZoneManual(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsZoneManual),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsZoneManualIntro,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(l10n.settingsZoneSafe),
            const SizedBox(height: 8),
            Text(l10n.settingsZoneRisk),
            const SizedBox(height: 8),
            Text(l10n.settingsZoneRestricted),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.settingsGotIt),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showPremiumConfirm(
      context,
      title: l10n.commonSignOutTitle,
      message: l10n.commonSignOutConfirmMessage,
      confirmLabel: l10n.commonSignOutButton,
      cancelLabel: l10n.commonCancel,
      icon: Icons.logout_rounded,
      severity: AppSeverity.critical,
    );
    if (ok && context.mounted) {
      await context.read<ProfileCubit>().signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (_) => false,
        );
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SettingsTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDEFF4)),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal dialog that captures a new password and drives [ProfileCubit].
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ProfileCubit>().changePassword(_passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (prev, curr) =>
          (prev.changingPassword && !curr.changingPassword),
      listener: (context, state) {
        if (state.passwordChanged) {
          Navigator.of(context).pop();
          AppSnack.success(context, l10n.settingsPasswordChanged);
        }
      },
      builder: (context, state) {
        return AlertDialog(
          title: Text(l10n.settingsUpdatePassword),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  autofocus: true,
                  enabled: !state.changingPassword,
                  decoration: InputDecoration(
                    labelText: l10n.settingsNewPasswordLabel,
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
                  validator: (v) => (v == null || v.length < 8)
                      ? l10n.settingsPasswordMinLength
                      : null,
                ),
                if (state.passwordError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    localizedErrorMessage(context, state.passwordError!),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.changingPassword
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: state.changingPassword ? null : () => _submit(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: state.changingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.settingsChangePasswordSubmit),
            ),
          ],
        );
      },
    );
  }
}

/// Settings row hosting the language switcher (primary location — the
/// secondary one is Supervisor Alerts' header, since supervisors never see
/// this screen).
class _LanguageTile extends StatelessWidget {
  final String label;
  const _LanguageTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecorations.card(radius: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          const LanguageToggle(),
        ],
      ),
    );
  }
}
