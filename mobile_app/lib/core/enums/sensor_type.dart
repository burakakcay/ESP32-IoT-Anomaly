library;

import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';

enum SensorType { temperature, humidity, acceleration, gyroscope }

extension SensorTypeExtension on SensorType {
  String getTitle(AppLocalizations l10n) {
    switch (this) {
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

  IconData get icon {
    switch (this) {
      case SensorType.temperature:
        return Icons.thermostat;

      case SensorType.humidity:
        return Icons.water_drop;

      case SensorType.acceleration:
        return Icons.speed;

      case SensorType.gyroscope:
        return Icons.explore;
    }
  }
}
