/// ESP32 cihazının kimliğini, son güncelleme zamanını ve bağlantı durumunu gösterir.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinel/core/enums/device_connection_status.dart';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/widgets/common/status_dot.dart';

class DeviceInfoCard extends StatelessWidget {
  final String deviceId;
  final DateTime? lastUpdate;
  final DeviceConnectionStatus connectionStatus;

  const DeviceInfoCard({
    super.key,
    required this.deviceId,
    required this.lastUpdate,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final statusLabel = switch (connectionStatus) {
      DeviceConnectionStatus.checking => l10n.serverConnecting,
      DeviceConnectionStatus.online => l10n.connected,
      DeviceConnectionStatus.stale => l10n.deviceStale,
      DeviceConnectionStatus.serverUnavailable => l10n.serverUnavailable,
      DeviceConnectionStatus.dataError => l10n.sensorDataError,
    };

    final statusColor = switch (connectionStatus) {
      DeviceConnectionStatus.online => SensorStatus.normal,
      DeviceConnectionStatus.checking ||
      DeviceConnectionStatus.stale => SensorStatus.warning,
      DeviceConnectionStatus.serverUnavailable ||
      DeviceConnectionStatus.dataError => SensorStatus.critical,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    deviceId.replaceAll('_', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (connectionStatus == DeviceConnectionStatus.checking)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(statusLabel)),
                ],
              )
            else
              StatusDot(status: statusColor, label: statusLabel),

            const SizedBox(height: 16),

            Text(
              l10n.lastUpdate,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 4),

            Text(
              lastUpdate == null
                  ? '--'
                  : DateFormat('dd.MM.yyyy HH:mm').format(lastUpdate!),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
