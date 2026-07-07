import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/locale_cubit.dart';
import '../config/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Two-segment EN/ES language switcher. Used in both `settings_screen.dart`
/// (primary location) and `supervisor_alerts_screen.dart`'s header
/// (secondary — supervisors never see the Settings tab).
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.neutralSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'EN',
            tooltip: l10n.commonLanguageEnglish,
            selected: locale.languageCode == 'en',
            onTap: () =>
                context.read<LocaleCubit>().changeLocale(const Locale('en')),
          ),
          _Segment(
            label: 'ES',
            tooltip: l10n.commonLanguageSpanish,
            selected: locale.languageCode == 'es',
            onTap: () =>
                context.read<LocaleCubit>().changeLocale(const Locale('es')),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
