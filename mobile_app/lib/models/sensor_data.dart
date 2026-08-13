/// ------------------------------------------------------------
/// SensorData Model
/// ------------------------------------------------------------
///
/// ESP32 tarafından gönderilen tek bir sensör paketini temsil eder.
///
/// JSON örneği:
///
/// {
///   "device_id": "...",
///   "sicaklik": 28.5,
///   "nem": 52.1,
///   ...
/// }
///
/// Bu model:
/// - JSON -> Dart dönüşümü yapar.
/// - Dart -> JSON dönüşümü yapar.
///
/// ------------------------------------------------------------
library;

import 'package:sentinel/models/acceleration.dart';
import 'package:sentinel/models/gyroscope.dart';

class SensorData {
  final String deviceId;
  final DateTime timestamp;
  final double temperature;
  final double humidity;

  final Acceleration acceleration;
  final Gyroscope gyroscope;

  SensorData({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.acceleration,
    required this.gyroscope,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json["device_id"],
      timestamp: DateTime.parse(json["zaman"]),
      temperature: (json["sicaklik"] as num).toDouble(),
      humidity: (json["nem"] as num).toDouble(),
      acceleration: Acceleration.fromJson(json["ivme"]),
      gyroscope: Gyroscope.fromJson(json["jiro"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "device_id": deviceId,
      "zaman": timestamp.toIso8601String(),
      "sicaklik": temperature,
      "nem": humidity,
      "ivme": acceleration.toJson(),
      "jiro": gyroscope.toJson(),
    };
  }

  factory SensorData.fromFirestoreJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json["device_id"] as String,
      timestamp: DateTime.parse(json["timestamp"] as String),
      temperature: (json["temperature"] as num).toDouble(),
      humidity: (json["humidity"] as num).toDouble(),
      acceleration: Acceleration(
        x: (json["accel_x"] as num).toInt(),
        y: (json["accel_y"] as num).toInt(),
        z: (json["accel_z"] as num).toInt(),
      ),
      gyroscope: Gyroscope(
        x: (json["gyro_x"] as num).toInt(),
        y: (json["gyro_y"] as num).toInt(),
        z: (json["gyro_z"] as num).toInt(),
      ),
    );
  }
}
