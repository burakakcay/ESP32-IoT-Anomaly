import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel/models/sensor_data.dart';

void main() {
  final sampleJson = {
    "device_id": "ESP32_Sensor_Node_001",
    "zaman": "2026-07-30T16:49:56",
    "sicaklik": 28.5,
    "nem": 49.6,
    "ivme": {"x": -1008, "y": 13992, "z": 6632},
    "jiro": {"x": -334, "y": -180, "z": 78},
  };

  group('SensorData.fromJson()', () {
    final sensor = SensorData.fromJson(sampleJson);

    test('deviceId doğru okunuyor', () {
      expect(sensor.deviceId, 'ESP32_Sensor_Node_001');
    });

    test('sicaklik doğru okunuyor', () {
      expect(sensor.temperature, 28.5);
    });

    test('nem doğru okunuyor', () {
      expect(sensor.humidity, 49.6);
    });

    test('ivme doğru okunuyor', () {
      expect(sensor.acceleration.x, -1008);
      expect(sensor.acceleration.y, 13992);
      expect(sensor.acceleration.z, 6632);
    });

    test('gyro doğru okunuyor', () {
      expect(sensor.gyroscope.x, -334);
      expect(sensor.gyroscope.y, -180);
      expect(sensor.gyroscope.z, 78);
    });

    test('zaman doğru parse ediliyor', () {
      expect(sensor.timestamp.year, 2026);
      expect(sensor.timestamp.month, 7);
      expect(sensor.timestamp.day, 30);
    });
  });

  group('SensorData.toJson()', () {
    final sensor = SensorData.fromJson(sampleJson);
    final json = sensor.toJson();

    test('deviceId doğru yazılıyor', () {
      expect(json["device_id"], "ESP32_Sensor_Node_001");
    });

    test('timestamp doğru yazılıyor', () {
      expect(
        json["zaman"],
        DateTime.parse("2026-07-30T16:49:56").toIso8601String(),
      );
    });

    test('sıcaklık doğru yazılıyor', () {
      expect(json["sicaklik"], 28.5);
    });

    test('nem doğru yazılıyor', () {
      expect(json["nem"], 49.6);
    });

    test('ivme doğru yazılıyor', () {
      expect(json["ivme"]["x"], -1008);
      expect(json["ivme"]["y"], 13992);
      expect(json["ivme"]["z"], 6632);
    });

    test('gyro doğru yazılıyor', () {
      expect(json["jiro"]["x"], -334);
      expect(json["jiro"]["y"], -180);
      expect(json["jiro"]["z"], 78);
    });
  });
}
