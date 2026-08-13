/// ------------------------------------------------------------
/// SensorStatusHelper
/// ------------------------------------------------------------
///
/// Sensör verilerini yorumlar.
///
/// Bu sınıf:
/// - Sıcaklığı değerlendirir.
/// - Nemi değerlendirir.
/// - Sonuç olarak bir SensorStatus döndürür.
///
/// Örnek:
///
/// final status =
///     SensorStatusHelper.temperatureStatus(42);
///
/// Sonuç:
///
/// SensorStatus.warning
///
/// Bu sınıf UI ile ilgilenmez.
/// Sadece iş mantığını (Business Logic) içerir.
///
/// ------------------------------------------------------------
library;

import 'dart:math';

import 'package:sentinel/models/acceleration.dart';
import 'package:sentinel/models/gyroscope.dart';

import '../enums/sensor_status.dart';

class SensorStatusHelper {
  SensorStatusHelper._();

  static SensorStatus getTemperatureStatus(double temperature) {
    if (temperature < 40) {
      return SensorStatus.normal;
    } else if (temperature < 60) {
      return SensorStatus.warning;
    } else if (temperature < 80) {
      return SensorStatus.danger;
    } else {
      return SensorStatus.critical;
    }
  }

  static SensorStatus getHumidityStatus(double humidity) {
    if (humidity >= 30 && humidity <= 60) {
      return SensorStatus.normal;
    } else if ((humidity >= 20 && humidity < 30) ||
        (humidity > 60 && humidity <= 70)) {
      return SensorStatus.warning;
    } else if ((humidity >= 10 && humidity < 20) ||
        (humidity > 70 && humidity <= 80)) {
      return SensorStatus.danger;
    } else {
      return SensorStatus.critical;
    }
  }

static SensorStatus getAccelerationStatus(Acceleration acceleration) {
    final x = acceleration.x.toDouble();
    final y = acceleration.y.toDouble();
    final z = acceleration.z.toDouble();

    final magnitude = sqrt((x * x) + (y * y) + (z * z));

    final g = magnitude / 16384.0;

    if (g > 3.0) {
      return SensorStatus.critical;
    } else if (g > 2.0) {
      return SensorStatus.danger;
    } else if (g > 1.5) {
      return SensorStatus.warning;
    }

    return SensorStatus.normal;
  }

  static SensorStatus getGyroscopeStatus(Gyroscope gyroscope) {
    final x = gyroscope.x.abs();
    final y = gyroscope.y.abs();
    final z = gyroscope.z.abs();

    if (x > 20000 || y > 20000 || z > 2000) {
      return SensorStatus.critical;
    }
    if (x > 12000 || y > 12000 || z > 12000) {
      return SensorStatus.danger;
    }
    if (x > 5000 || y > 5000 || z > 5000) {
      return SensorStatus.warning;
    }
    return SensorStatus.normal;
  }
}
