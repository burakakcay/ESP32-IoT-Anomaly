import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_type.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/services/sensor_history_device.dart';
import 'package:sentinel/widgets/charts/sensor_chart.dart';

class SensorDetailScreen extends StatelessWidget {
  final SensorType sensorType;
  final SensorHistoryService historyService;

  const SensorDetailScreen({
    super.key,
    required this.sensorType,
    required this.historyService,
  });

  String getTitle(AppLocalizations l10n) {
    switch (sensorType) {
      case SensorType.temperature:
        return l10n.temperature;
      case SensorType.humidity:
        return l10n.humidity;
      case SensorType.acceleration:
        return l10n.acceleration;
      case SensorType.gyroscope:
        return l10n.gyroscope;
    }
  }

  List<double> getChartValues() {
    switch (sensorType) {
      case SensorType.temperature:
        return historyService.temperatures;

      case SensorType.humidity:
        return historyService.humidities;

      case SensorType.acceleration:
      case SensorType.gyroscope:
        return [];
    }
  }

  List<double>? getChartValuesX() {
    switch (sensorType) {
      case SensorType.acceleration:
        return historyService.accelerationX
            .map((value) => value.toDouble())
            .toList();
      case SensorType.gyroscope:
        return historyService.gyroscopeX
            .map((value) => value.toDouble())
            .toList();
      case SensorType.temperature:
      case SensorType.humidity:
        return null;
    }
  }

  List<double>? getChartValuesY() {
    switch (sensorType) {
      case SensorType.acceleration:
        return historyService.accelerationY
            .map((value) => value.toDouble())
            .toList();
      case SensorType.gyroscope:
        return historyService.gyroscopeY
            .map((value) => value.toDouble())
            .toList();
      case SensorType.temperature:
      case SensorType.humidity:
        return null;
    }
  }

  List<double>? getChartValuesZ() {
    switch (sensorType) {
      case SensorType.acceleration:
        return historyService.accelerationZ
            .map((value) => value.toDouble())
            .toList();
      case SensorType.gyroscope:
        return historyService.gyroscopeZ
            .map((value) => value.toDouble())
            .toList();
      case SensorType.temperature:
      case SensorType.humidity:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final min = switch (sensorType) {
      SensorType.temperature => historyService.minTemperature,
      SensorType.humidity => historyService.minHumidity,
      _ => null,
    };

    final max = switch (sensorType) {
      SensorType.temperature => historyService.maxTemperature,
      SensorType.humidity => historyService.maxHumidity,
      _ => null,
    };

    final average = switch (sensorType) {
      SensorType.temperature => historyService.averageTemperature,
      SensorType.humidity => historyService.averageHumidity,
      _ => null,
    };

    final unit = sensorType == SensorType.temperature ? "°C" : "%";

    return Scaffold(
      appBar: AppBar(title: Text(getTitle(l10n))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sensorType.icon, size: 72),

            const SizedBox(height: 24),

            Text(
              sensorType.getTitle(l10n),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            if (sensorType == SensorType.temperature ||
                sensorType == SensorType.humidity)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatistic(
                        title: l10n.minimum,
                        value: min,
                        unit: unit,
                      ),
                      _buildStatistic(
                        title: l10n.average,
                        value: average,
                        unit: unit,
                      ),
                      _buildStatistic(
                        title: l10n.maximum,
                        value: max,
                        unit: unit,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            SensorChart(
              values: getChartValues(),
              timestamps: historyService.timestamps,
              valuesX: getChartValuesX(),
              valuesY: getChartValuesY(),
              valuesZ: getChartValuesZ(),
              isAcceleration: sensorType == SensorType.acceleration,
              isGyroscope: sensorType == SensorType.gyroscope,
            ),
          ],
        ),
      ),
    );
  }
}

Column _buildStatistic({
  required String title,
  double? value,
  required String unit,
}) {
  return Column(
    children: [
      Text(title, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        value == null ? "--" : "${value.toStringAsFixed(1)} $unit",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
