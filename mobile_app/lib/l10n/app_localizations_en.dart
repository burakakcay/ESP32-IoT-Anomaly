// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get device => 'Device';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get normal => 'Normal';

  @override
  String get warning => 'Warning';

  @override
  String get high => 'High';

  @override
  String get critical => 'Critical';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get acceleration => 'Acceleration';

  @override
  String get gyroscope => 'Gyroscope';
}
