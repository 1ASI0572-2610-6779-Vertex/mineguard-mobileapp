import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/domain/entities/session_user.dart';
import 'package:mobile_iot/shared/application/session_cubit.dart';
import 'package:mobile_iot/analytics/presentation/performance/performance_screen.dart';
import 'package:mobile_iot/profile/presentation/settings/settings_screen.dart';
import 'package:mobile_iot/assets/presentation/vehicle-selection/vehicle_selection_screen.dart';

class OperatorHomeScreen extends StatefulWidget {
  final SessionUser user;
  const OperatorHomeScreen({super.key, required this.user});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  // Ephemeral UI-only state (which tab is selected) — not business/async
  // state, so plain setState is the right tool, not a bloc.
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state ?? widget.user;

    final tabs = <Widget>[
      const VehicleSelectionScreen(),
      const PerformanceScreen(),
      SettingsScreen(user: user),
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
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: AppColors.primary),
            label: 'Performance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
