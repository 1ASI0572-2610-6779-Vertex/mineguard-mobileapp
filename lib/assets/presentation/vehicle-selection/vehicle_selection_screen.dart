import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/application/session_cubit.dart';
import 'package:mobile_iot/shared/widgets/greeting_header.dart';
import '../../../injections.dart';
import '../../domain/entities/vehicle.dart';
import 'bloc/bloc.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late final VehicleSelectionBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = serviceLocator<VehicleSelectionBloc>();
    // Guarded: this bloc is a lazy singleton (survives tab switches), so only
    // dispatch the initial fetch the first time it's ever mounted.
    if (_bloc.state.status == VehicleSelectionStatus.initial) {
      _bloc.add(const FetchVehiclesEvent());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state;

    return BlocProvider<VehicleSelectionBloc>.value(
      value: _bloc,
      child: BlocListener<VehicleSelectionBloc, VehicleSelectionState>(
        listenWhen: (previous, current) =>
            previous.assigning && !current.assigning,
        listener: (context, state) {
          if (state.assignError == null && state.assigned != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Shift started: ${state.assigned!.name}'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        child: Column(
          children: [
            if (user != null) GreetingHeader(user: user),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  const Text(
                    'Vehicle Selection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Select the unit assigned for today's shift",
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<VehicleSelectionBloc, VehicleSelectionState>(
                    builder: (context, state) => Column(
                      children: [
                        _AssignedCard(
                          vehicle: state.assigned,
                          assigning: state.assigning,
                        ),
                        if (state.assignError != null) ...[
                          const SizedBox(height: 8),
                          _InlineError(message: state.assignError!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by vehicle',
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
                  BlocBuilder<VehicleSelectionBloc, VehicleSelectionState>(
                    builder: (context, state) {
                      switch (state.status) {
                        case VehicleSelectionStatus.initial:
                        case VehicleSelectionStatus.loading:
                          return const _VehicleListSkeleton();
                        case VehicleSelectionStatus.error:
                          return _ErrorRetry(
                            error: state.errorMessage ?? 'Unknown error',
                            onRetry: () => _bloc.add(const FetchVehiclesEvent()),
                          );
                        case VehicleSelectionStatus.loaded:
                          final filtered = state.vehicles.where((v) {
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
                                  'No vehicles found.',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
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
                                      selected: state.assigned?.id ==
                                          filtered[i].id,
                                      onTap: filtered[i].status ==
                                                  VehicleStatus.available &&
                                              !state.assigning
                                          ? () => _bloc.add(
                                              AssignVehicleEvent(filtered[i]))
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          );
                      }
                    },
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
                  hasVehicle ? vehicle!.name : 'No vehicle assigned',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasVehicle
                      ? '${vehicle!.category} · active shift'
                      : 'Select an available unit',
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
        'Available',
        AppColors.successSoft,
        AppColors.success,
      ),
      VehicleStatus.inUse => (
        'In use',
        AppColors.neutralSoft,
        AppColors.textSecondary,
      ),
      VehicleStatus.maintenance => (
        'Maintenance',
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
            'Failed to load vehicles',
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
            label: const Text('Retry'),
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
