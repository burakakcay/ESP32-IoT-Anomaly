import 'package:sentinel/models/sensor_data.dart';

class DeviceSummary {
  final String id;
  final bool isDemo;
  final SensorData? lastReading;

  const DeviceSummary({
    required this.id,
    this.isDemo = false,
    this.lastReading,
  });

  DateTime? get lastUpdate => lastReading?.timestamp;

  bool hasRecentReading({
    required DateTime now,
    Duration freshnessTreshold = const Duration(seconds: 45),
  }) {
    final timestamp = lastUpdate;

    if (timestamp == null) return false;

    final age = now.difference(timestamp);
    return !age.isNegative && age <= freshnessTreshold;
  }
}
