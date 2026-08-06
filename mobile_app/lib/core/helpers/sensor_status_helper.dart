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

import '../enums/sensor_status.dart';

class SensorStatusHelper {
  SensorStatusHelper._();

  static SensorStatus temperatureStatus(double temperature) {
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

  static SensorStatus humidityStatus(double humidity) {
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
}
