import 'package:flutter/material.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';
import 'package:mobile_iot/analytics/presentation/performance/performance_view.dart';
import 'package:mobile_iot/profile/presentation/settings/settings_view.dart';
import 'package:mobile_iot/assets/presentation/vehicle-selection/vehicle_selection_view.dart';

class OperatorHomeView extends StatefulWidget {
  final SessionUser user;
  const OperatorHomeView({super.key, required this.user});

  @override
  State<OperatorHomeView> createState() => _OperatorHomeViewState();
}

class _OperatorHomeViewState extends State<OperatorHomeView> {
  int _index = 0;
  Vehicle? _assignedVehicle;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      VehicleSelectionView(
        user: widget.user,
        assigned: _assignedVehicle,
        onAssign: (v) => setState(() => _assignedVehicle = v),
      ),
      PerformanceView(user: widget.user),
      SettingsView(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundMuted,
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.backgroundCard,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: AppColors.primary),
            label: 'Desempeño',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
