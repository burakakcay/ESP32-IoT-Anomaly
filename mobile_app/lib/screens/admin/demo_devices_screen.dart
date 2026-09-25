import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/core/helpers/sensor_status_helper.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/device_summary.dart';
import 'package:sentinel/widgets/cards/acceleration_card.dart';
import 'package:sentinel/widgets/cards/gyroscope_card.dart';
import 'package:sentinel/widgets/cards/sensor_card.dart';

class DemoDevicesScreen extends StatelessWidget {
  final DeviceSummary device;

  const DemoDevicesScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reading = device.lastReading;
    final temperature = reading?.temperature;
    final humidity = reading?.humidity;

    return Scaffold(
      appBar: AppBar(title: Text(device.id)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Chip(label: Text(l10n.demoLabel)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.demoDeviceNotice)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (reading == null)
                  Center(child: Text(l10n.noData))
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 4
                          : constraints.maxWidth >= 400
                          ? 2
                          : 1;
                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 210,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        children: [
                          SensorCard(
                            title: l10n.temperature,
                            value: temperature?.toStringAsFixed(1) ?? '--',
                            unit: '°C',
                            icon: Icons.thermostat,
                            status: temperature == null
                                ? SensorStatus.normal
                                : SensorStatusHelper.getTemperatureStatus(
                                    temperature,
                                  ),
                          ),
                          SensorCard(
                            title: l10n.humidity,
                            value: humidity?.toStringAsFixed(1) ?? '--',
                            unit: '%',
                            icon: Icons.water_drop,
                            status: humidity == null
                                ? SensorStatus.normal
                                : SensorStatusHelper.getHumidityStatus(
                                    humidity,
                                  ),
                          ),
                          AccelerationCard(acceleration: reading.acceleration),
                          GyroscopeCard(gyroscope: reading.gyroscope),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
