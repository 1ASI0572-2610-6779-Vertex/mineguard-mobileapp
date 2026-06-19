import 'package:flutter/material.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/infrastructure/data_sources/mocks.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';
import 'package:mobile_iot/iam/presentation/sign-in/sign_in_view.dart';
import 'package:mobile_iot/shared/widgets/greeting_header.dart';

class SupervisorAlertsView extends StatefulWidget {
  final SessionUser user;
  const SupervisorAlertsView({super.key, required this.user});

  @override
  State<SupervisorAlertsView> createState() => _SupervisorAlertsViewState();
}

class _SupervisorAlertsViewState extends State<SupervisorAlertsView> {
  late List<SafetyAlert> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = List.of(MockApi.recentAlerts());
  }

  void _markReviewed(SafetyAlert alert) {
    setState(() => _alerts.removeWhere((a) => a.id == alert.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${alert.title}" marcada como revisada')),
    );
  }

  void _callCabin(SafetyAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Llamando a cabina por "${alert.title}"…')),
    );
  }

  Future<void> _logout() async {
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
    if (ok == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInView()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMuted,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Stack(
              children: [
                GreetingHeader(
                  user: widget.user,
                  background: AppColors.supervisorAccent,
                ),
                Positioned(
                  top: 16,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.textOnDark,
                    ),
                    tooltip: 'Cerrar sesión',
                    onPressed: _logout,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Text(
                    'HOY - RECIENTES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_alerts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 40,
                              color: AppColors.success,
                            ),
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
                    )
                  else
                    ..._alerts.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AlertCard(
                          alert: a,
                          onAction: () {
                            switch (a.kind) {
                              case AlertKind.panic:
                                _callCabin(a);
                                break;
                              case AlertKind.fatigue:
                                _markReviewed(a);
                                break;
                              case AlertKind.collisionRisk:
                                break;
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SafetyAlert alert;
  final VoidCallback onAction;

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: soft,
                  shape: BoxShape.circle,
                ),
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
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              alert.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          if (alert.primaryAction != null) ...[
            const SizedBox(height: 12),
            _ActionButton(
              kind: alert.kind,
              label: alert.primaryAction!,
              onTap: onAction,
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

  const _ActionButton({
    required this.kind,
    required this.label,
    required this.onTap,
  });

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
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      child: Text(label),
    );
  }
}
