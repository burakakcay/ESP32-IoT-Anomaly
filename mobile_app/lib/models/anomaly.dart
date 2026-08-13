class Measurement {
  final num value;
  final num median;
  final num mad;
  final num robustZScore;
  final bool isAnomaly;

  Measurement({
    required this.value,
    required this.median,
    required this.mad,
    required this.robustZScore,
    required this.isAnomaly,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      value: json['value'],
      median: json['median'],
      mad: json['mad'],
      robustZScore: json['robustZScore'],
      isAnomaly: json['isAnomaly'],
    );
  }
}

class AnomalyResult {
  final String timestamp;
  final int anomalyCount;
  final bool isAnomaly;
  final Map<String, Measurement> measurements;

  AnomalyResult({
    required this.timestamp,
    required this.anomalyCount,
    required this.isAnomaly,
    required this.measurements,
  });

  factory AnomalyResult.fromJson(Map<String, dynamic> json) {
    final measurementsJson = json['measurements'] as Map<String, dynamic>;

    return AnomalyResult(
      timestamp: json['timestamp'],
      anomalyCount: json['anomalyCount'],
      isAnomaly: json['isAnomaly'],
      measurements: measurementsJson.map(
        (key, value) => MapEntry(key, Measurement.fromJson(value)),
      ),
    );
  }
}

class AnomalyResponse {
  final String deviceId;
  final int analyzedReadings;
  final int anomalyReadings;
  final List<AnomalyResult> results;

  AnomalyResponse({
    required this.deviceId,
    required this.analyzedReadings,
    required this.anomalyReadings,
    required this.results,
  });

  factory AnomalyResponse.fromJson(Map<String, dynamic> json) {
    return AnomalyResponse(
      deviceId: json['device_id'],
      analyzedReadings: json['analyzedReadings'],
      anomalyReadings: json['anomalyReadings'],
      results: (json['results'] as List)
          .map((item) => AnomalyResult.fromJson(item))
          .toList(),
    );
  }
}
