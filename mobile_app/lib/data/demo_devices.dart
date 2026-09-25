import 'package:sentinel/models/acceleration.dart';
import 'package:sentinel/models/device_summary.dart';
import 'package:sentinel/models/gyroscope.dart';
import 'package:sentinel/models/sensor_data.dart';

List<DeviceSummary> createDemoDevices(DateTime now) {
  DeviceSummary createDevice({
    required String id,
    required Duration age,
    required double temperature,
    required double humidity,
  }) {
    return DeviceSummary(
      id: id,
      isDemo: true,
      lastReading: SensorData(
        deviceId: id,
        timestamp: now.subtract(age),
        temperature: temperature,
        humidity: humidity,
        acceleration: Acceleration(x: 120, y: -80, z: 16384),
        gyroscope: Gyroscope(x: 12, y: -8, z: 5),
      ),
    );
  }

  return [
    createDevice(
      id: 'ESP32_Sensor_Node_002_Demo',
      age: const Duration(seconds: 5),
      temperature: 24.6,
      humidity: 46.2,
    ),
    createDevice(
      id: 'ESP32_Sensor_Node_003_Demo',
      age: const Duration(minutes: 20),
      temperature: 22.8,
      humidity: 51.4,
    ),
    createDevice(
      id: 'ESP32_Sensor_Node_004_Demo',
      age: const Duration(seconds: 10),
      temperature: 48.5,
      humidity: 32.0,
    ),
  ];
}
