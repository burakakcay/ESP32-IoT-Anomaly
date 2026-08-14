/// ESP32 cihazının kimliğini, son güncelleme zamanını ve bağlantı durumunu gösterir.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/widgets/common/status_dot.dart';

class DeviceInfoCard extends StatelessWidget {
  final String deviceId;
  final DateTime lastUpdate;
  final bool isConnected;

  const DeviceInfoCard({
    super.key,
    required this.deviceId,
    required this.lastUpdate,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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

            StatusDot(
              status: isConnected ? SensorStatus.normal : SensorStatus.critical,
              label: isConnected ? l10n.connected : l10n.disconnected,
            ),

            const SizedBox(height: 16),

            Text(
              l10n.lastUpdate,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 4),

            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(lastUpdate),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
