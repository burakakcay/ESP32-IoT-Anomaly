/// ------------------------------------------------------------
/// SensorHistoryService
/// ------------------------------------------------------------
///
/// Sensör geçmişini RAM üzerinde tutar.
///
/// Görevleri:
/// - Yeni veri eklemek
/// - Geçmiş verileri okumak
/// - Son veriyi döndürmek
/// - Geçmişi temizlemek
/// - Grafikler için veri sağlamak
///
/// ------------------------------------------------------------
library;

import 'package:sentinel/models/sensor_data.dart';

class SensorHistoryService {
  static const int maxHistory = 100;

  final List<SensorData> _history = [];

  List<SensorData> get history => List.unmodifiable(_history);

  List<double> get temperatures => _history.map((e) => e.temperature).toList();

  List<double> get humidities => _history.map((e) => e.humidity).toList();

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
    if (_history.isEmpty) return null;

    return temperatures.reduce((a, b) => a < b ? a : b);
  }
  double? get maxTemperature {
    if (_history.isEmpty) return null;

    return temperatures.reduce((a, b) => a > b ? a : b);
  }
  double? get averageTemperature {
    if (_history.isEmpty) return null;

    final values = temperatures;

    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get minHumidity {
    if (_history.isEmpty) return null;

    return humidities.reduce((a, b) => a < b ? a : b);
  }
  double? get maxHumidity {
    if (_history.isEmpty) return null;

    return humidities.reduce((a, b) => a > b ? a : b);
  }
  double? get averageHumidity {
    if (_history.isEmpty) return null;

    final values = humidities;

    return values.reduce((a, b) => a + b) / values.length;
  }

  void clear() {
    _history.clear();
  }
}
