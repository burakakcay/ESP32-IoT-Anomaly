import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';

class AdminShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const AdminShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    final destinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: Text(l10n.adminOverview),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.devices_other_outlined),
        selectedIcon: const Icon(Icons.devices_other),
        label: Text(l10n.adminDevices),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.warning_amber_outlined),
        selectedIcon: const Icon(Icons.warning_rounded),
        label: Text(l10n.anomalyHistory),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: l10n.adminOverview,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.devices_other_outlined),
                  label: l10n.adminDevices,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: l10n.anomalyHistory,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 1100,
                backgroundColor: colors.surface,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Icon(
                    Icons.sensors_rounded,
                    color: colors.primary,
                    size: 36,
                  ),
                ),
                destinations: destinations,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
