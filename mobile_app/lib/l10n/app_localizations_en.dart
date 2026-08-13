// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sentinel';

  @override
  String get device => 'Device';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get packets => 'Packets';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get acceleration => 'Acceleration';

  @override
  String get gyroscope => 'Gyroscope';

  @override
  String get normal => 'Normal';

  @override
  String get warning => 'Warning';

  @override
  String get high => 'High';

  @override
  String get critical => 'Critical';

  @override
  String get minimum => 'Min';

  @override
  String get average => 'Average';

  @override
  String get maximum => 'Max';

  @override
  String get noData => 'No data available';

  @override
  String get anomalyStatus => 'Anomaly Status';

  @override
  String get anomalyDataLoading => 'Anomaly data is loading...';

  @override
  String get systemNormal => 'System normal. No anomalies detected.';

  @override
  String anomaliesDetected(int count) {
    return '$count anomalies detected.';
  }

  @override
  String measurementsAnalyzed(int count) {
    return '$count measurements analyzed.';
  }

  @override
  String get latestAnomaly => 'Latest Anomaly';

  @override
  String get aiAnalysis => 'AI Anomaly Analysis';

  @override
  String get aiAnalysisLoading => 'AI analysis is loading...';

  @override
  String get possibleCause => 'Possible Cause';

  @override
  String get affectedSensors => 'Affected Sensors';

  @override
  String get anomalyHistory => 'Anomaly History';

  @override
  String get detectedAnomalies => 'Detected Anomalies';

  @override
  String get analyzedMeasurements => 'Measurements Analyzed';

  @override
  String unusualValuesDetected(int count) {
    return 'Unusual values detected in $count sensors.';
  }
}
