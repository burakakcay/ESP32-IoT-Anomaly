/// ESP32'den gelen sensör paketini JSON ile Dart arasında dönüştürür.
library;

import 'package:sentinel/models/acceleration.dart';
import 'package:sentinel/models/gyroscope.dart';

class SensorData {
  final String deviceId;
  final DateTime timestamp;
  final double? temperature;
  final double? humidity;

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
      temperature: _optionalMeasurement(json["sicaklik"]),
      humidity: _optionalMeasurement(json["nem"]),
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
      temperature: _optionalMeasurement(json["temperature"]),
      humidity: _optionalMeasurement(json["humidity"]),
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

  static double? _optionalMeasurement(Object? value) {
    if (value == null) return null;
    final number = (value as num).toDouble();
    return number.isFinite ? number : null;
  }
}
