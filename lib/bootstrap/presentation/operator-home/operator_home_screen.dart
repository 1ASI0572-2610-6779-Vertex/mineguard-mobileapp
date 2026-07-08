import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_iot/shared/config/app_colors.dart';
import 'package:mobile_iot/shared/domain/entities/session_user.dart';
import 'package:mobile_iot/shared/application/session_cubit.dart';
import 'package:mobile_iot/analytics/presentation/performance/performance_screen.dart';
import 'package:mobile_iot/profile/presentation/settings/settings_screen.dart';
import 'package:mobile_iot/assets/presentation/vehicle-selection/vehicle_selection_screen.dart';
import 'package:mobile_iot/l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    final tabs = <Widget>[
      const VehicleSelectionScreen(),
      const PerformanceScreen(),
      SettingsScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundMuted,
      // Tab bodies extend to the bottom edge; each tab's header handles the
      // top notch inset itself, so no SafeArea is needed here.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        // Key on the index so the switcher animates between tabs.
        child: KeyedSubtree(key: ValueKey(_index), child: tabs[_index]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          border: const Border(
            top: BorderSide(color: Color(0xFFEDEFF4), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.transparent,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.directions_car_outlined),
              selectedIcon: const Icon(
                Icons.directions_car,
                color: AppColors.primary,
              ),
              label: l10n.bootstrapNavHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.show_chart_outlined),
              selectedIcon: const Icon(
                Icons.show_chart,
                color: AppColors.primary,
              ),
              label: l10n.bootstrapNavPerformance,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person, color: AppColors.primary),
              label: l10n.bootstrapNavProfile,
            ),
          ],
        ),
      ),
    );
  }
}
