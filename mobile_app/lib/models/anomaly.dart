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

class AiAnalysis {
  final String summary;
  final String severity;
  final String? possibleCause;
  final List<String> affectedSensors;

  AiAnalysis({
    required this.summary,
    required this.severity,
    required this.possibleCause,
    required this.affectedSensors,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      summary: json['summary'] as String,
      severity: json['severity'] as String,
      possibleCause: json['possibleCause'] as String?,
      affectedSensors: List<String>.from(json['affectedSensors'] as List),
    );
  }
}

class AiAnomalyResponse {
  final String deviceId;
  final int analyzedReadings;
  final int anomalyReadings;
  final List<AnomalyResult> anomalies;
  final AiAnalysis aiAnalysis;

  AiAnomalyResponse({
    required this.deviceId,
    required this.analyzedReadings,
    required this.anomalyReadings,
    required this.anomalies,
    required this.aiAnalysis,
  });

  factory AiAnomalyResponse.fromJson(Map<String, dynamic> json) {
    return AiAnomalyResponse(
      deviceId: json['device_id'] as String,
      analyzedReadings: json['analyzedReadings'] as int,
      anomalyReadings: json['anomalyReadings'] as int,
      anomalies: (json['anomalies'] as List)
          .map((item) => AnomalyResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      aiAnalysis: AiAnalysis.fromJson(
        json['aiAnalysis'] as Map<String, dynamic>,
      ),
    );
  }
}
