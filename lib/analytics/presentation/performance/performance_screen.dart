import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/config/app_theme.dart';
import 'package:mobile_iot/shared/application/session_cubit.dart';
import 'package:mobile_iot/shared/widgets/greeting_header.dart';
import 'package:mobile_iot/shared/widgets/localized_error_message.dart';
import 'package:mobile_iot/l10n/generated/app_localizations.dart';
import '../../../injections.dart';
import '../../domain/entities/performance_stats.dart';
import 'bloc/bloc.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  late final PerformanceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = serviceLocator<PerformanceBloc>();
    // Guarded: this bloc is a lazy singleton (survives tab switches), so
    // only dispatch the initial fetch the first time it's ever mounted.
    if (_bloc.state.status == PerformanceStatus.initial) {
      _bloc.add(const FetchPerformanceEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state;
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider<PerformanceBloc>.value(
      value: _bloc,
      child: Column(
        children: [
          if (user != null) GreetingHeader(user: user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.performanceTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.performanceSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                BlocBuilder<PerformanceBloc, PerformanceState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case PerformanceStatus.initial:
                      case PerformanceStatus.loading:
                        return const _PerformanceSkeleton();
                      case PerformanceStatus.error:
                        return _ErrorRetry(
                          error: state.error ?? l10n.commonUnknownError,
                          onRetry: () =>
                              _bloc.add(const FetchPerformanceEvent()),
                        );
                      case PerformanceStatus.loaded:
                        return _PerformanceContent(stats: state.stats!);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the main content once metrics are available.
class _PerformanceContent extends StatelessWidget {
  final PerformanceStats stats;
  const _PerformanceContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _AnimatedCard(
          delay: 0,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    label: l10n.performanceSafetyScoreLabel,
                    value: '${stats.safetyScore}',
                    suffix: '/100',
                    footer: l10n.performanceSafetyScoreDelta(
                      stats.safetyScoreDelta,
                    ),
                    footerColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: l10n.performanceFatigueAlertsLabel,
                    value: '${stats.fatigueAlerts}',
                    footer: l10n.performanceFatigueAlertsFooter,
                    footerColor: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AnimatedCard(
          delay: 80,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: AppDecorations.card(radius: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.warningSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.schedule, color: AppColors.warning),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.performanceHoursDrivenTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.performanceHoursLimitSubtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.performanceHoursValue(stats.drivingHours),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.performanceHoursOfLimit(stats.drivingHoursLimit),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AnimatedCard(delay: 160, child: _HoursProgressBar(stats: stats)),
      ],
    );
  }
}

/// Shift progress bar based on hours driven vs. the limit.
class _HoursProgressBar extends StatelessWidget {
  final PerformanceStats stats;
  const _HoursProgressBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = (stats.drivingHours / stats.drivingHoursLimit).clamp(
      0.0,
      1.0,
    );
    final isNearLimit = ratio > 0.8;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.performanceProgressLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isNearLimit ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.neutralSoft,
              valueColor: AlwaysStoppedAnimation(
                isNearLimit ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable card for a summarized metric with a contextual footer.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String footer;
  final Color footerColor;

  const _StatTile({
    required this.label,
    required this.value,
    this.suffix,
    required this.footer,
    required this.footerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              children: [
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: TextStyle(
              color: footerColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

/// Loading state with visual skeletons to avoid layout jumps.
class _PerformanceSkeleton extends StatelessWidget {
  const _PerformanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 90, height: 10),
                      const SizedBox(height: 10),
                      _SkeletonBox(width: 60, height: 30),
                      const SizedBox(height: 8),
                      _SkeletonBox(width: 100, height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 90, height: 10),
                      const SizedBox(height: 10),
                      _SkeletonBox(width: 40, height: 30),
                      const SizedBox(height: 8),
                      _SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _SkeletonBox(width: 44, height: 44, radius: 999),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 120, height: 14),
                    const SizedBox(height: 6),
                    _SkeletonBox(width: 90, height: 11),
                  ],
                ),
              ),
              _SkeletonBox(width: 50, height: 22),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple animated block used as a loading placeholder.
class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 6.0,
  });
  final double width, height, radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Error state with a retry action to recover the load.
class _ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
          const SizedBox(height: 10),
          Text(
            l10n.performanceLoadError,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error is String
                ? error as String
                : localizedErrorMessage(context, error),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

/// Wraps cards to animate their appearance with fade and slide.
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
