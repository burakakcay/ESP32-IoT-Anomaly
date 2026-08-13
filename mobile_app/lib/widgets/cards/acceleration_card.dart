/// ------------------------------------------------------------
/// AccelerationCard
/// ------------------------------------------------------------
///
/// MPU6050 sensöründen gelen ivme (X, Y, Z) verilerini gösterir.
///
/// Kart:
/// - İvme eksenlerini gösterir.
/// - SensorStatusHelper ile durum hesaplar.
/// - StatusDot ile durum bilgisini gösterir.
///
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/core/helpers/sensor_status_helper.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/acceleration.dart';
import 'package:sentinel/widgets/common/status_dot.dart';

class AccelerationCard extends StatelessWidget {
  final Acceleration? acceleration;
  final VoidCallback? onTap;

  const AccelerationCard({super.key, this.acceleration, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final status = acceleration == null
        ? SensorStatus.normal
        : SensorStatusHelper.getAccelerationStatus(acceleration!);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.acceleration,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildAxisRow("X", acceleration?.x),
                const SizedBox(height: 8),

                _buildAxisRow("Y", acceleration?.y),
                const SizedBox(height: 8),

                _buildAxisRow("Z", acceleration?.z),
                const Spacer(),

                Center(child: StatusDot(status: status)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAxisRow(String axis, int? value) {
    return Row(
      children: [
        Text(axis, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value?.toString() ?? "--"),
      ],
    );
  }
}
