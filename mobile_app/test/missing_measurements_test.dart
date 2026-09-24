import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/services/sensor_history_device.dart';

Map<String, dynamic> reading(int second, {num? temperature, num? humidity}) => {
  'device_id': 'test-device',
  'timestamp': DateTime(2026, 9, 24, 14, 0, second).toIso8601String(),
  'temperature': temperature,
  'humidity': humidity,
  'accel_x': 100,
  'accel_y': 200,
  'accel_z': 300,
  'gyro_x': 1,
  'gyro_y': 2,
  'gyro_z': 3,
};

void main() {
  test('Missing measurements preserve the other sensor data', () {
    final json = reading(0, humidity: 34.3)..remove('temperature');
    final data = SensorData.fromFirestoreJson(json);
    expect(data.temperature, isNull);
    expect(data.humidity, 34.3);
    expect(data.acceleration.x, 100);
    expect(data.gyroscope.z, 3);
  });

  test('Statistics and chart timestamps exclude missing values independently', () {
    final history = SensorHistoryService();
    history.add(SensorData.fromFirestoreJson(reading(0, temperature: 20)));
    history.add(SensorData.fromFirestoreJson(reading(15, humidity: 40)));
    history.add(SensorData.fromFirestoreJson(
      reading(30, temperature: 30, humidity: 60),
    ));
    expect(history.length, 3);
    expect(history.temperatures, [20.0, 30.0]);
    expect(history.humidities, [40.0, 60.0]);
    expect(history.temperatureTimestamps.map((t) => t.second), [0, 30]);
    expect(history.humidityTimestamps.map((t) => t.second), [15, 30]);
    expect(history.minTemperature, 20);
    expect(history.maxTemperature, 30);
    expect(history.averageTemperature, 25);
    expect(history.minHumidity, 40);
    expect(history.maxHumidity, 60);
    expect(history.averageHumidity, 50);
    expect(history.accelerationX, [100, 100, 100]);
  });

  test('All missing or non-finite measurements produce empty statistics', () {
    final history = SensorHistoryService();
    history.add(SensorData.fromFirestoreJson(reading(0)));
    history.add(SensorData.fromFirestoreJson(
      reading(15, temperature: double.nan, humidity: double.infinity),
    ));
    expect(history.temperatures, isEmpty);
    expect(history.humidities, isEmpty);
    expect(history.temperatureTimestamps, isEmpty);
    expect(history.humidityTimestamps, isEmpty);
    expect(history.minTemperature, isNull);
    expect(history.maxTemperature, isNull);
    expect(history.averageTemperature, isNull);
    expect(history.minHumidity, isNull);
    expect(history.maxHumidity, isNull);
    expect(history.averageHumidity, isNull);
  });
}
