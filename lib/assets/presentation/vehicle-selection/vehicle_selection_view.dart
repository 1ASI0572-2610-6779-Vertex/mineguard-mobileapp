import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';
import 'package:mobile_iot/shared/widgets/greeting_header.dart';
import 'vehicle_selection_controller.dart';

class VehicleSelectionView extends ConsumerStatefulWidget {
  const VehicleSelectionView({super.key});

  @override
  ConsumerState<VehicleSelectionView> createState() =>
      _VehicleSelectionViewState();
}

class _VehicleSelectionViewState extends ConsumerState<VehicleSelectionView> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final ctrlState = ref.watch(vehicleSelectionControllerProvider);

    return Column(
      children: [
        if (user != null) GreetingHeader(user: user),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              const Text(
                'Selección de Vehículo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecciona la unidad asignada para tu turno de hoy',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _AssignedCard(
                vehicle: ctrlState.assigned,
                assigning: ctrlState.assigning,
              ),
              if (ctrlState.assignError != null) ...[
                const SizedBox(height: 8),
                _InlineError(message: ctrlState.assignError!),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por vehículo',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ctrlState.vehicles.when(
                loading: () => const _VehicleListSkeleton(),
                error: (e, _) => _ErrorRetry(
                  error: e,
                  onRetry: () => ref
                      .read(vehicleSelectionControllerProvider.notifier)
                      .refresh(),
                ),
                data: (vehicles) {
                  final filtered = vehicles.where((v) {
                    if (_query.isEmpty) return true;
                    final q = _query.toLowerCase();
                    return v.name.toLowerCase().contains(q) ||
                        v.category.toLowerCase().contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No encontramos vehículos.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AnimatedCard(
                            delay: i * 60,
                            child: _VehicleTile(
                              vehicle: filtered[i],
                              selected:
                                  ctrlState.assigned?.id == filtered[i].id,
                              onTap: filtered[i].status ==
                                          VehicleStatus.available &&
                                      !ctrlState.assigning
                                  ? () => _assign(filtered[i])
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _assign(Vehicle v) async {
    await ref
        .read(vehicleSelectionControllerProvider.notifier)
        .assignVehicle(v);
    if (!mounted) return;
    final error =
        ref.read(vehicleSelectionControllerProvider).assignError;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Turno iniciado: ${v.name}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _AssignedCard extends StatelessWidget {
  final Vehicle? vehicle;
  final bool assigning;
  const _AssignedCard({required this.vehicle, required this.assigning});

  @override
  Widget build(BuildContext context) {
    final hasVehicle = vehicle != null;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
          ),
        ],
      ),
      child: assigning
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: hasVehicle
                        ? AppColors.successSoft
                        : AppColors.warningSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasVehicle
                        ? Icons.check_circle
                        : Icons.report_problem_rounded,
                    size: 30,
                    color:
                        hasVehicle ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  hasVehicle ? vehicle!.name : 'Sin vehículo asignado',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasVehicle
                      ? '${vehicle!.category} · turno activo'
                      : 'Selecciona una unidad disponible',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback? onTap;
  const _VehicleTile({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.vehicleIconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_filled,
                  color: AppColors.vehicleIcon,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: disabled
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.category,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: vehicle.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final VehicleStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      VehicleStatus.available => (
        'Disponible',
        AppColors.successSoft,
        AppColors.success,
      ),
      VehicleStatus.inUse => (
        'En uso',
        AppColors.neutralSoft,
        AppColors.textSecondary,
      ),
      VehicleStatus.maintenance => (
        'Mantenimiento',
        AppColors.warningSoft,
        AppColors.warning,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Error al cargar vehículos',
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
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

class _VehicleListSkeleton extends StatelessWidget {
  const _VehicleListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _SkeletonBox(width: 44, height: 44, radius: 12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 120, height: 14),
                      const SizedBox(height: 6),
                      _SkeletonBox(width: 80, height: 11),
                    ],
                  ),
                ),
                _SkeletonBox(width: 72, height: 26, radius: 999),
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
    this.radius = 8.0,
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
