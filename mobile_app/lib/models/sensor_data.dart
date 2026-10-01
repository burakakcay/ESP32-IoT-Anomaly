/// ESP32'den gelen sensör paketini JSON ile Dart arasında dönüştürür.
library;

import 'package:sentinel/models/acceleration.dart';
import 'package:sentinel/models/gyroscope.dart';

class SensorData {
  final String deviceId;
  final DateTime timestamp;
  final double? temperature;
  final double? humidity;
  final double? lastRmsG;
  final double? peakG;
  final int? vibrationIntervalMs;
  final int? vibrationLastAgeMs;
  final int? vibrationWindowCount;
  final bool? vibrationSaturated;
  final bool? vibrationSamplingError;

  final Acceleration acceleration;
  final Gyroscope gyroscope;

  SensorData({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.acceleration,
    required this.gyroscope,
    this.lastRmsG,
    this.peakG,
    this.vibrationIntervalMs,
    this.vibrationLastAgeMs,
    this.vibrationWindowCount,
    this.vibrationSaturated,
    this.vibrationSamplingError,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['device_id'],
      timestamp: DateTime.parse(json['zaman']),
      temperature: _optionalMeasurement(json['sicaklik']),
      humidity: _optionalMeasurement(json['nem']),
      acceleration: Acceleration.fromJson(json['ivme']),
      gyroscope: Gyroscope.fromJson(json['jiro']),
      lastRmsG: _optionalMeasurement(json['last_rms_g']),
      peakG: _optionalMeasurement(json['peak_g']),
      vibrationIntervalMs: (json['vibration_interval_ms'] as num?)?.toInt(),
      vibrationLastAgeMs: (json['vibration_last_age_ms'] as num?)?.toInt(),
      vibrationWindowCount: (json['vibration_window_count'] as num?)?.toInt(),
      vibrationSaturated: json['vibration_saturated'] as bool?,
      vibrationSamplingError: json['vibration_sampling_error'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'zaman': timestamp.toIso8601String(),
      'sicaklik': temperature,
      'nem': humidity,
      'ivme': acceleration.toJson(),
      'jiro': gyroscope.toJson(),
      'last_rms_g': lastRmsG,
      'peak_g': peakG,
      'vibration_interval_ms': vibrationIntervalMs,
      'vibration_last_age_ms': vibrationLastAgeMs,
      'vibration_window_count': vibrationWindowCount,
      'vibration_saturated': vibrationSaturated,
      'vibration_sampling_error': vibrationSamplingError,
    };
  }

  factory SensorData.fromFirestoreJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['device_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      temperature: _optionalMeasurement(json['temperature']),
      humidity: _optionalMeasurement(json['humidity']),
      acceleration: Acceleration(
        x: (json['accel_x'] as num).toInt(),
        y: (json['accel_y'] as num).toInt(),
        z: (json['accel_z'] as num).toInt(),
      ),
      gyroscope: Gyroscope(
        x: (json['gyro_x'] as num).toInt(),
        y: (json['gyro_y'] as num).toInt(),
        z: (json['gyro_z'] as num).toInt(),
      ),
      lastRmsG: _optionalMeasurement(json['last_rms_g']),
      peakG: _optionalMeasurement(json['peak_g']),
      vibrationIntervalMs: (json['vibration_interval_ms'] as num?)?.toInt(),
      vibrationLastAgeMs: (json['vibration_last_age_ms'] as num?)?.toInt(),
      vibrationWindowCount: (json['vibration_window_count'] as num?)?.toInt(),
      vibrationSaturated: json['vibration_saturated'] as bool?,
      vibrationSamplingError: json['vibration_sampling_error'] as bool?,
    );
  }

  static double? _optionalMeasurement(Object? value) {
    if (value == null) return null;
    final number = (value as num).toDouble();
    return number.isFinite ? number : null;
  }
}
