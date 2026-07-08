import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/config/app_theme.dart';

/// Centralized, premium user-feedback primitives: toasts and confirm dialogs.
///
/// Every transient message and confirmation shares one polished, animated,
/// glassmorphic presentation whose intensity is driven by a **severity
/// hierarchy** modelled on MineGuard's safety logic:
///
///  • [AppSeverity.critical] — Collision Detected / Panic Button. Intense
///    semantic red, energetic entrance, longer on-screen time and an explicit
///    dismiss affordance. Demands immediate attention.
///  • [AppSeverity.warning] — Fatigue Detected / Proximity Alerts. Warm amber.
///    Reviewable, non-blocking; carries a gentle "needs attention" pulse.
///  • [AppSeverity.info] — general brand-colored messages.
///  • [AppSeverity.success] — positive confirmations (green).
///
/// Regardless of color, every component keeps the frosted-glass, premium look:
/// the severity color is applied to the icon, the container border and — subtly
/// — the container's glow.
enum AppSeverity { critical, warning, info, success }

/// Resolved presentation for a given [AppSeverity].
class _SeverityStyle {
  final Color accent;
  final IconData icon;

  /// How long a toast lingers before auto-dismissing.
  final Duration duration;

  /// Energetic, attention-grabbing entrance (pop + shake). Critical only.
  final bool emphatic;

  /// Continuous "reviewable" micro-animation on the icon + glow. Warning only.
  final bool pulse;

  /// Shows an explicit close control and persists longer. Critical only.
  final bool dismissible;

  const _SeverityStyle({
    required this.accent,
    required this.icon,
    required this.duration,
    this.emphatic = false,
    this.pulse = false,
    this.dismissible = false,
  });
}

/// Semantic, non-flat critical red (distinct from the softer inline
/// `AppColors.error` used for form validation).
const Color _criticalRed = Color(0xFFDC2626);

_SeverityStyle _styleFor(AppSeverity severity) {
  switch (severity) {
    case AppSeverity.critical:
      return const _SeverityStyle(
        accent: _criticalRed,
        icon: Icons.crisis_alert_rounded,
        duration: Duration(seconds: 8),
        emphatic: true,
        dismissible: true,
      );
    case AppSeverity.warning:
      return const _SeverityStyle(
        accent: AppColors.warning,
        icon: Icons.warning_amber_rounded,
        duration: Duration(seconds: 6),
        pulse: true,
      );
    case AppSeverity.info:
      return const _SeverityStyle(
        accent: AppColors.primary,
        icon: Icons.info_rounded,
        duration: Duration(seconds: 4),
      );
    case AppSeverity.success:
      return const _SeverityStyle(
        accent: AppColors.success,
        icon: Icons.check_circle_rounded,
        duration: Duration(seconds: 3),
      );
  }
}

// ── Toasts ───────────────────────────────────────────────────────────────────

class AppSnack {
  const AppSnack._();

  /// Collision / panic-grade alert: intense red, energetic, persistent.
  static void critical(BuildContext context, String message) =>
      show(context, message, AppSeverity.critical);

  /// Fatigue / proximity-grade alert: warm amber, reviewable, pulsing.
  static void warning(BuildContext context, String message) =>
      show(context, message, AppSeverity.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, AppSeverity.info);

  static void success(BuildContext context, String message) =>
      show(context, message, AppSeverity.success);

  /// Back-compat alias — an error is treated as a critical-severity alert.
  static void error(BuildContext context, String message) =>
      show(context, message, AppSeverity.critical);

  static void show(BuildContext context, String message, AppSeverity severity) {
    final style = _styleFor(severity);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          duration: style.duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: _SnackContent(
            message: message,
            style: style,
            onClose: style.dismissible
                ? () => messenger.hideCurrentSnackBar()
                : null,
          ),
        ),
      );
  }
}

/// The animated, glassmorphic body of a toast. Drives the severity-specific
/// entrance (energetic pop + shake for critical) and the reviewable pulse
/// (warning), while keeping the frosted-glass surface for every severity.
class _SnackContent extends StatefulWidget {
  final String message;
  final _SeverityStyle style;
  final VoidCallback? onClose;

  const _SnackContent({
    required this.message,
    required this.style,
    this.onClose,
  });

  @override
  State<_SnackContent> createState() => _SnackContentState();
}

class _SnackContentState extends State<_SnackContent>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.style.emphatic ? 640 : 420),
    )..forward();
    if (widget.style.pulse) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1150),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final accent = style.accent;
    final introCurve = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutBack,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _pulse]),
      builder: (context, _) {
        final pulseT = _pulse?.value ?? 0.0;

        // Entrance: a bigger pop for critical, a gentle one otherwise.
        final base = style.emphatic ? 0.82 : 0.92;
        final scale = base + (1 - base) * introCurve.value;

        // Critical shakes briefly on entry to grab the eye; it damps to zero.
        final shake = style.emphatic
            ? math.sin(_intro.value * math.pi * 5) * (1 - _intro.value) * 5
            : 0.0;

        // The glow breathes for warnings and burns steady-and-strong for
        // critical; info/success stay subtle.
        final double glowAlpha;
        final double glowBlur;
        if (style.emphatic) {
          glowAlpha = 0.42;
          glowBlur = 30;
        } else if (style.pulse) {
          glowAlpha = 0.20 + 0.22 * pulseT;
          glowBlur = 18 + 10 * pulseT;
        } else {
          glowAlpha = 0.16;
          glowBlur = 18;
        }

        final iconScale = style.pulse ? 1.0 + 0.10 * pulseT : 1.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF1A1D2E).withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(
                          alpha: style.pulse ? 0.45 + 0.25 * pulseT : 0.55,
                        ),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: iconScale,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Icon(style.icon, color: accent, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (widget.onClose != null) ...[
                          const SizedBox(width: 4),
                          InkResponse(
                            onTap: widget.onClose,
                            radius: 20,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Confirm dialog ───────────────────────────────────────────────────────────

/// A frosted, animated confirmation dialog whose accent (icon, border, glow and
/// confirm button) is driven by [severity]. Returns `true` when confirmed.
Future<bool> showPremiumConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData? icon,
  AppSeverity severity = AppSeverity.info,
}) async {
  final style = _styleFor(severity);
  final accent = style.accent;
  final resolvedIcon = icon ?? style.icon;
  final emphatic = style.emphatic;

  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: Duration(milliseconds: emphatic ? 340 : 280),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
      // Critical confirmations pop with a touch more energy.
      final curved = CurvedAnimation(
        parent: anim,
        curve: emphatic ? Curves.elasticOut : Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5 * anim.value,
          sigmaY: 5 * anim.value,
        ),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: emphatic ? 0.88 : 0.92,
              end: 1,
            ).animate(curved),
            child: Center(
              child: _ConfirmCard(
                title: title,
                message: message,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                icon: resolvedIcon,
                accent: accent,
              ),
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

class _ConfirmCard extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color accent;

  const _ConfirmCard({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          color: Colors.transparent,
          // Frosted-glass card: the accent tints the hairline border and the
          // glow, keeping the premium look consistent across severities.
          child: GlassContainer(
            radius: 26,
            blur: 22,
            tintOpacity: 0.86,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            border: Border.all(
              color: accent.withValues(alpha: 0.30),
              width: 1.4,
            ),
            shadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
              ...AppShadows.elevated,
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.30)),
                  ),
                  child: Icon(icon, color: accent, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: accent.withValues(alpha: 0.45),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
