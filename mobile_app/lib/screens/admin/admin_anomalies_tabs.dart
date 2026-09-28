import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/screens/admin/admin_anomalies_screen.dart';
import 'package:sentinel/screens/admin/anomaly_history_screen.dart';

class AdminAnomaliesTabs extends StatefulWidget {
  const AdminAnomaliesTabs({super.key});

  @override
  State<AdminAnomaliesTabs> createState() => _AdminAnomaliesTabsState();
}

class _AdminAnomaliesTabsState extends State<AdminAnomaliesTabs> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: colors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: colors.outline.withValues(alpha: 0.15),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              onTap: (index) {
                if (index == _selectedTab) return;

                setState(() => _selectedTab = index);
              },

              tabs: [
                Tab(text: l10n.latestAnalysisTab),
                Tab(text: l10n.savedHistoryTab),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? const AdminAnomaliesScreen()
                : const AnomalyHistoryScreen(),
          ),
        ],
      ),
    );
  }
}
