import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/device_summary.dart';

class AdminOverviewScreen extends StatelessWidget {
  final List<DeviceSummary> devices;

  const AdminOverviewScreen({
    super.key,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final realDevices = devices.where((device) => !device.isDemo).toList();
    final demoCount = devices.where((device) => device.isDemo).length;

    final recentCount = realDevices
        .where((device) => device.hasRecentReading(now: now))
        .length;

    final staleCount = realDevices
        .where(
          (device) =>
              device.lastReading != null && !device.hasRecentReading(now: now),
        )
        .length;

    final noDataCount = realDevices
        .where((device) => device.lastReading == null)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminOverview)),
      body: Align(
        alignment: Alignment.center,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 500
                    ? 2
                    : 1;

                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 120 +
                        (MediaQuery.textScalerOf(context).scale(32) - 32)
                            .clamp(0, double.infinity),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SummaryCard(
                      title: l10n.realDevices,
                      count: realDevices.length,
                      icon: Icons.devices_other,
                      accent: colors.primary,
                    ),
                    _SummaryCard(
                      title: l10n.recentDeviceData,
                      count: recentCount,
                      icon: Icons.check_circle_outline,
                      accent: const Color(0xFF81C784),
                    ),
                    _SummaryCard(
                      title: l10n.deviceStale,
                      count: staleCount,
                      icon: Icons.schedule,
                      accent: const Color(0xFFFFCA62),
                    ),
                    _SummaryCard(
                      title: l10n.noData,
                      count: noDataCount,
                      icon: Icons.sensors_off,
                      accent: colors.onSurfaceVariant,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${l10n.demoDevices}: $demoCount',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Text(
                  l10n.demoExcludedFromSummary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color accent;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
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
