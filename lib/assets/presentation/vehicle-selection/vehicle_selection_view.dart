import 'package:flutter/material.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/infrastructure/data_sources/mocks.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';
import 'package:mobile_iot/shared/widgets/greeting_header.dart';

class VehicleSelectionView extends StatefulWidget {
  final SessionUser user;
  final Vehicle? assigned;
  final ValueChanged<Vehicle> onAssign;

  const VehicleSelectionView({
    super.key,
    required this.user,
    required this.assigned,
    required this.onAssign,
  });

  @override
  State<VehicleSelectionView> createState() => _VehicleSelectionViewState();
}

class _VehicleSelectionViewState extends State<VehicleSelectionView> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = MockApi.vehicles().where((v) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return v.name.toLowerCase().contains(q) ||
          v.category.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        GreetingHeader(user: widget.user),
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
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _AssignedCard(vehicle: widget.assigned),
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
              if (vehicles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No encontramos vehículos.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...vehicles.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VehicleTile(
                        vehicle: v,
                        selected: widget.assigned?.id == v.id,
                        onTap: v.status == VehicleStatus.available
                            ? () {
                                widget.onAssign(v);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Asignado: ${v.name}'),
                                  ),
                                );
                              }
                            : null,
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignedCard extends StatelessWidget {
  final Vehicle? vehicle;
  const _AssignedCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final hasVehicle = vehicle != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
              hasVehicle ? Icons.check_circle : Icons.report_problem_rounded,
              size: 30,
              color: hasVehicle ? AppColors.success : AppColors.warning,
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
                ? '${vehicle!.category} · listo para tu turno'
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
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
              const SizedBox(width: 12),
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
