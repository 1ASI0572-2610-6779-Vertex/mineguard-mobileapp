import 'package:flutter/material.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/domain/entities/session_user.dart';
import 'package:mobile_iot/l10n/generated/app_localizations.dart';

class GreetingHeader extends StatelessWidget {
  final SessionUser user;
  final Color background;

  const GreetingHeader({
    super.key,
    required this.user,
    this.background = AppColors.surfaceDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.sharedGreeting(user.fullName),
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textOnDarkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.sharedWorkerIdLabel(user.workerId),
                      style: const TextStyle(
                        color: AppColors.textOnDarkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
