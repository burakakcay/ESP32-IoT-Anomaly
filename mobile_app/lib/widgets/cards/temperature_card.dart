/// ------------------------------------------------------------
/// TemperatureCard
/// ------------------------------------------------------------
///
/// Sıcaklık bilgisini kullanıcıya gösterir.
///
/// Kart:
/// - Sıcaklığı gösterir.
/// - SensorStatusHelper ile durumu hesaplar.
/// - StatusDot widget'ını kullanır.
///
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:sentinel/core/helpers/sensor_status_helper.dart';
import 'package:sentinel/widgets/cards/sensor_card.dart';

class TemperatureCard extends StatelessWidget {
  final double temperature;

  const TemperatureCard({super.key, required this.temperature});

  @override
  Widget build(BuildContext context) {
    final status = SensorStatusHelper.temperatureStatus(temperature);

    return SensorCard(
      title: "Temperature",
      value: temperature.toStringAsFixed(1),
      unit: "°C",
      icon: Icons.thermostat,
      status: status,
    );
  }
}
