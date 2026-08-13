import 'package:flutter/material.dart';
import 'package:sentinel/core/helpers/sensor_status_helper.dart';
import 'package:sentinel/widgets/cards/sensor_card.dart';

class HumidityCard extends StatelessWidget {
  final double humidity;

  const HumidityCard({super.key, required this.humidity});

  @override
  Widget build(BuildContext context) {
    return SensorCard(
      title: "Humidity",
      value: humidity.toStringAsFixed(1),
      unit: "%",
      icon: Icons.water_drop,
      status: SensorStatusHelper.getHumidityStatus(humidity),
    );
  }
}
