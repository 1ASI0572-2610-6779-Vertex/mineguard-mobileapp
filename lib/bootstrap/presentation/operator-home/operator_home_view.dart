import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/domain/entities/models.dart';
import 'package:mobile_iot/shared/api/session_provider.dart';
import 'package:mobile_iot/analytics/presentation/performance/performance_view.dart';
import 'package:mobile_iot/profile/presentation/settings/settings_view.dart';
import 'package:mobile_iot/assets/presentation/vehicle-selection/vehicle_selection_view.dart';

class OperatorHomeView extends ConsumerStatefulWidget {
  final SessionUser user;
  const OperatorHomeView({super.key, required this.user});

  @override
  ConsumerState<OperatorHomeView> createState() => _OperatorHomeViewState();
}

class _OperatorHomeViewState extends ConsumerState<OperatorHomeView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider) ?? widget.user;

    final tabs = <Widget>[
      const VehicleSelectionView(),
      const PerformanceView(),
      SettingsView(user: user),
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
