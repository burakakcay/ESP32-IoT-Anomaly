import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/device_summary.dart';

class DevicesScreen extends StatelessWidget {
  final List<DeviceSummary> devices;
  final ValueChanged<DeviceSummary> onDeviceSelected;

  const DevicesScreen({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDevices)),
      body: devices.isEmpty
          ? Center(child: Text(l10n.noData))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];

                final statusText = device.lastReading == null
                    ? l10n.noData
                    : device.hasRecentReading(now: now)
                    ? l10n.connected
                    : l10n.deviceStale;

                final lastUpdate = device.lastUpdate;
                final formattedTime = lastUpdate == null
                    ? '--'
                    : '${MaterialLocalizations.of(context).formatShortDate(lastUpdate)} '
                          '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(lastUpdate), alwaysUse24HourFormat: true)}';

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.memory),
                    title: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(device.id),
                        if (device.isDemo)
                          Chip(
                            label: Text(l10n.demoLabel),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$statusText\n'
                        '${l10n.lastUpdate}: $formattedTime',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onDeviceSelected(device),
                  ),
                );
              },
            ),
    );
  }
}
