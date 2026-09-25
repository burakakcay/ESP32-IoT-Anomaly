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

  @override
  String get connectionChecking => 'Checking';

  @override
  String get deviceStale => 'Data outdated';

  @override
  String get serverUnavailable => 'Server unreachable';

  @override
  String get sensorDataError => 'Data error';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get loginFieldsRequired => 'Enter your email and password.';

  @override
  String get loginInvalidCredentials => 'Incorrect email or password.';

  @override
  String get loginNetworkError => 'Check your internet connection.';

  @override
  String get loginTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get loginFailed => 'Unable to sign in. Please try again.';

  @override
  String get signOutButton => 'Sign out';

  @override
  String get loginSubtitle => 'Keep track of your sensors.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signOutFailed => 'Unable to sign out. Please try again.';

  @override
  String get serverConnecting => 'Connecting to server…';

  @override
  String get aiAnalysisFailed =>
      'Unable to load AI analysis. Please try again later.';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminDevices => 'Devices';

  @override
  String get demoLabel => 'Demo';

  @override
  String get demoDeviceNotice =>
      'This screen displays sample readings. No live device is connected.';

  @override
  String get realDevices => 'Real devices';

  @override
  String get recentDeviceData => 'Recent readings';

  @override
  String get demoDevices => 'Demo devices';

  @override
  String get demoExcludedFromSummary =>
      'Demo devices are excluded from the status counts above.';

  @override
  String get latestAnalysisResults => 'Latest analysis results';

  @override
  String get refreshData => 'Refresh';

  @override
  String get anomalyLoadFailed =>
      'Unable to load analysis results. Use Refresh to try again.';

  @override
  String get latestAnalysisNotice =>
      'Only anomalies in the latest batch of readings are shown. This is not a permanent anomaly history.';

  @override
  String get measurementValue => 'Reading';

  @override
  String get baselineMedian => 'Baseline median';

  @override
  String get analyzeWithAi => 'Analyze with AI';

  @override
  String get aiResultsScope =>
      'The list shows up to the last 10 anomalies used for the AI interpretation. Cached results may be used.';
}
