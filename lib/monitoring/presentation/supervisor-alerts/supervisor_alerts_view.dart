import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';
import 'package:mobile_iot/shared/widgets/greeting_header.dart';
import 'package:mobile_iot/iam/api/iam_providers.dart';
import 'package:mobile_iot/iam/presentation/sign-in/sign_in_view.dart';
import 'alerts_controller.dart';

class SupervisorAlertsView extends ConsumerWidget {
  const SupervisorAlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final alertsAsync = ref.watch(alertsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundMuted,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Stack(
              children: [
                if (user != null)
                  GreetingHeader(
                    user: user,
                    background: AppColors.supervisorAccent,
                  ),
                Positioned(
                  top: 16,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.textOnDark),
                    tooltip: 'Cerrar sesión',
                    onPressed: () => _logout(context, ref),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(alertsControllerProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    const Text(
                      'HOY · RECIENTES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    alertsAsync.when(
                      loading: () => const _AlertsSkeleton(),
                      error: (e, _) => _ErrorRetry(
                        error: e,
                        onRetry: () =>
                            ref.read(alertsControllerProvider.notifier).refresh(),
                      ),
                      data: (alerts) => _AlertsList(alerts: alerts),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(sessionProvider.notifier).state = null;
      ref.invalidate(alertsControllerProvider);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInView()),
          (_) => false,
        );
      }
    }
  }
}

class _AlertsList extends ConsumerWidget {
  final List<SafetyAlert> alerts;
  const _AlertsList({required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 40, color: AppColors.success),
              SizedBox(height: 8),
              Text(
                'Sin alertas pendientes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < alerts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnimatedCard(
              delay: i * 70,
              child: _AlertCard(
                alert: alerts[i],
                onAction: (alertId) async {
                  await ref
                      .read(alertsControllerProvider.notifier)
                      .markReviewed(alertId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('"${alerts[i].title}" marcada como revisada'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SafetyAlert alert;
  final ValueChanged<String> onAction;
  const _AlertCard({required this.alert, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final (icon, color, soft) = switch (alert.kind) {
      AlertKind.panic => (
        Icons.error,
        AppColors.error,
        AppColors.errorSoft,
      ),
      AlertKind.collisionRisk => (
        Icons.warning_amber_rounded,
        AppColors.error,
        AppColors.errorSoft,
      ),
      AlertKind.fatigue => (
        Icons.show_chart,
        AppColors.warning,
        AppColors.warningSoft,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                alert.elapsedLabel,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              alert.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          if (alert.primaryAction != null) ...[
            const SizedBox(height: 14),
            _ActionButton(
              kind: alert.kind,
              label: alert.primaryAction!,
              onTap: () => onAction(alert.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AlertKind kind;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.kind, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (kind == AlertKind.panic) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.phone, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.backgroundMuted,
        side: BorderSide.none,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      child: Text(label),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _AlertsSkeleton extends StatelessWidget {
  const _AlertsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkeletonBox(width: 34, height: 34, radius: 999),
                    const SizedBox(width: 10),
                    Expanded(child: _SkeletonBox(width: 160, height: 15)),
                    const SizedBox(width: 8),
                    _SkeletonBox(width: 50, height: 11),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: double.infinity, height: 11),
                      const SizedBox(height: 5),
                      _SkeletonBox(width: 200, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    _anim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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

class _ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Error al cargar alertas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

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
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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
