import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/services/sensor_history_device.dart';

void main() {
  SensorData createSensorData(
    int minute, {
    double temperature = 25.0,
    double humidity = 50.0,
  }) {
    return SensorData.fromJson({
      'device_id': 'ESP32_Sensor_Node_001',
      'zaman': DateTime(2026, 8, 15, 12, minute).toIso8601String(),
      'sicaklik': temperature,
      'nem': humidity,
      'ivme': {'x': minute, 'y': minute + 1, 'z': minute + 2},
      'jiro': {'x': minute + 3, 'y': minute + 4, 'z': minute + 5},
    });
  }

  group('SensorHistoryService', () {
    late SensorHistoryService historyService;

    setUp(() {
      historyService = SensorHistoryService();
    });

    test('başlangıçta geçmiş boştur', () {
      expect(historyService.isEmpty, true);
      expect(historyService.length, 0);
      expect(historyService.last, isNull);

      expect(historyService.minTemperature, isNull);
      expect(historyService.maxTemperature, isNull);
      expect(historyService.averageTemperature, isNull);

      expect(historyService.minHumidity, isNull);
      expect(historyService.maxHumidity, isNull);
      expect(historyService.averageHumidity, isNull);
    });

    test('ölçümleri eklenme sırasıyla saklar', () {
      final firstReading = createSensorData(0);
      final secondReading = createSensorData(1);
      final thirdReading = createSensorData(2);

      historyService.add(firstReading);
      historyService.add(secondReading);
      historyService.add(thirdReading);

      expect(historyService.length, 3);
      expect(historyService.history, [
        firstReading,
        secondReading,
        thirdReading,
      ]);

      expect(historyService.timestamps, [
        firstReading.timestamp,
        secondReading.timestamp,
        thirdReading.timestamp,
      ]);

      expect(historyService.last, thirdReading);
    });

    test('art arda gelen aynı zaman damgalı ölçümü tekrar eklemez', () {
      final firstReading = createSensorData(0, temperature: 25.0);
      final duplicateReading = createSensorData(0, temperature: 99.0);

      historyService.add(firstReading);
      historyService.add(duplicateReading);

      expect(historyService.length, 1);
      expect(historyService.last?.temperature, 25.0);
    });

    test('en fazla 240 ölçüm saklar ve en eski ölçümü siler', () {
      final startTime = DateTime(2026, 8, 15, 12);

      for (var index = 0; index < 241; index++) {
        final timestamp = startTime.add(Duration(minutes: index));

        historyService.add(
          SensorData.fromJson({
            'device_id': 'ESP32_Sensor_Node_001',
            'zaman': timestamp.toIso8601String(),
            'sicaklik': 25.0,
            'nem': 50.0,
            'ivme': {'x': index, 'y': index, 'z': index},
            'jiro': {'x': index, 'y': index, 'z': index},
          }),
        );
      }

      expect(historyService.length, SensorHistoryService.maxHistory);
      expect(
        historyService.history.first.timestamp,
        startTime.add(const Duration(minutes: 1)),
      );
      expect(
        historyService.history.last.timestamp,
        startTime.add(const Duration(minutes: 240)),
      );
    });

    test('sıcaklık ve nem istatistiklerini doğru hesaplar', () {
      historyService.add(
        createSensorData(0, temperature: 20.0, humidity: 40.0),
      );
      historyService.add(
        createSensorData(1, temperature: 25.0, humidity: 50.0),
      );
      historyService.add(
        createSensorData(2, temperature: 30.0, humidity: 60.0),
      );

      expect(historyService.minTemperature, 20.0);
      expect(historyService.maxTemperature, 30.0);
      expect(historyService.averageTemperature, 25.0);

      expect(historyService.minHumidity, 40.0);
      expect(historyService.maxHumidity, 60.0);
      expect(historyService.averageHumidity, 50.0);
    });

    test('clear geçmişteki bütün ölçümleri temizler', () {
      historyService.add(createSensorData(0));
      historyService.add(createSensorData(1));

      historyService.clear();

      expect(historyService.isEmpty, true);
      expect(historyService.length, 0);
      expect(historyService.last, isNull);
    });
  });
}
