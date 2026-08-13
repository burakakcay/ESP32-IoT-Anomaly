/// ------------------------------------------------------------
/// DeviceInfoCard
/// ------------------------------------------------------------
///
/// ESP32 cihazına ait temel bilgileri gösterir.
///
/// Gösterilen bilgiler:
/// - Cihaz Kimliği
/// - Son Güncelleme Zamanı
/// - Bağlantı Durumu
///
/// ------------------------------------------------------------
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
  final int _packetCount;

  const DeviceInfoCard({
    super.key,
    required this.deviceId,
    required this.lastUpdate,
    required this.isConnected,
    required this._packetCount
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
                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    deviceId,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                StatusDot(
                  status: isConnected
                      ? SensorStatus.normal
                      : SensorStatus.critical,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              AppLocalizations.of(context)!.lastUpdate,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 4),

            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(lastUpdate),
              style: const TextStyle(fontSize: 13),
            ),

            const SizedBox(height: 12),

            Text(l10n.packets, style: Theme.of(context).textTheme.labelMedium),

            const SizedBox(height: 4),

            Text(
              _packetCount.toString(),
              style: Theme.of(context).textTheme.titleMedium,
            )
          ],
        ),
      ),
    );
  }
}
