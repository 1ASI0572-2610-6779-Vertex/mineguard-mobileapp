import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/config/app_theme.dart';
import 'package:mobile_iot/shared/domain/entities/session_user.dart';
import 'package:mobile_iot/l10n/generated/app_localizations.dart';

/// Premium, edge-to-edge greeting header.
///
/// Draws its gradient all the way to the top of the screen and pads its content
/// down by the device's top safe-area inset — so it renders correctly behind
/// the status bar and camera notch without the parent needing a `SafeArea`.
/// This is what keeps the greeting from colliding with the notch on the
/// operator tabs (which are not wrapped in a SafeArea).
class GreetingHeader extends StatelessWidget {
  final SessionUser user;

  /// Header gradient. Defaults to the deep-navy operator treatment; the
  /// supervisor screen passes [AppGradients.supervisorHeader].
  final Gradient gradient;

  /// Optional actions rendered at the top-right (e.g. language toggle, logout).
  final Widget? trailing;

  const GreetingHeader({
    super.key,
    required this.user,
    Gradient? gradient,
    this.trailing,
  }) : gradient = gradient ?? AppGradients.operatorHeader;

  String get _initials {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topInset = MediaQuery.of(context).padding.top;
    final tint = (gradient is LinearGradient)
        ? (gradient as LinearGradient).colors.last
        : AppColors.surfaceDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The gradient header sits behind the status bar, so its icons must be
      // light to stay legible. Sign-in (no header) keeps the global dark icons.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: AppShadows.header(tint),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: Stack(
            children: [
              // Decorative light bloom for depth — subtle, clipped by the header.
              Positioned(
                top: -60,
                right: -30,
                child: _GlowCircle(
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: -70,
                left: -40,
                child: _GlowCircle(
                  size: 160,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 18, 16, 26),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(initials: _initials),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.sharedGreeting(user.fullName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _WorkerIdChip(
                            label: l10n.sharedWorkerIdLabel(user.workerId),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.textOnDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _WorkerIdChip extends StatelessWidget {
  final String label;
  const _WorkerIdChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.badge_outlined,
            size: 13,
            color: AppColors.textOnDarkMuted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
