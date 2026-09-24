/// Sensör geçmişini bellekte tutar ve grafikler için veri sağlar.
library;

import 'package:sentinel/models/sensor_data.dart';

class SensorHistoryService {
  static const int maxHistory = 240;

  final List<SensorData> _history = [];

  List<SensorData> get history => List.unmodifiable(_history);

  List<double> get temperatures =>
      _history.map((e) => e.temperature).whereType<double>().toList();

  List<double> get humidities =>
      _history.map((e) => e.humidity).whereType<double>().toList();

  List<DateTime> get temperatureTimestamps => _history
      .where((e) => e.temperature != null)
      .map((e) => e.timestamp)
      .toList();

  List<DateTime> get humidityTimestamps => _history
      .where((e) => e.humidity != null)
      .map((e) => e.timestamp)
      .toList();

  List<int> get accelerationX => _history.map((e) => e.acceleration.x).toList();
  List<int> get accelerationY => _history.map((e) => e.acceleration.y).toList();
  List<int> get accelerationZ => _history.map((e) => e.acceleration.z).toList();

  List<int> get gyroscopeX => _history.map((e) => e.gyroscope.x).toList();
  List<int> get gyroscopeY => _history.map((e) => e.gyroscope.y).toList();
  List<int> get gyroscopeZ => _history.map((e) => e.gyroscope.z).toList();

  List<DateTime> get timestamps => _history.map((e) => e.timestamp).toList();

  SensorData? get last => _history.isEmpty ? null : _history.last;

  int get length => _history.length;

  bool get isEmpty => _history.isEmpty;

  bool get isNotEmpty => _history.isNotEmpty;

  void add(SensorData data) {
    if (_history.isNotEmpty && _history.last.timestamp == data.timestamp) {
      return;
    }

    _history.add(data);

    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }
  }

  double? get minTemperature {
    final values = temperatures;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }

  double? get maxTemperature {
    final values = temperatures;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  double? get averageTemperature {
    final values = temperatures;
    if (values.isEmpty) return null;

    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get minHumidity {
    final values = humidities;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }

  double? get maxHumidity {
    final values = humidities;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  double? get averageHumidity {
    final values = humidities;
    if (values.isEmpty) return null;

    return values.reduce((a, b) => a + b) / values.length;
  }

  void clear() {
    _history.clear();
  }
}
