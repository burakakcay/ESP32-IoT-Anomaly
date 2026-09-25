import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sentinel'**
  String get appName;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// No description provided for @packets.
  ///
  /// In en, this message translates to:
  /// **'Packets'**
  String get packets;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @acceleration.
  ///
  /// In en, this message translates to:
  /// **'Acceleration'**
  String get acceleration;

  /// No description provided for @gyroscope.
  ///
  /// In en, this message translates to:
  /// **'Gyroscope'**
  String get gyroscope;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @minimum.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minimum;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @maximum.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maximum;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @anomalyStatus.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Status'**
  String get anomalyStatus;

  /// No description provided for @anomalyDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Anomaly data is loading...'**
  String get anomalyDataLoading;

  /// No description provided for @systemNormal.
  ///
  /// In en, this message translates to:
  /// **'System normal. No anomalies detected.'**
  String get systemNormal;

  /// No description provided for @anomaliesDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} anomalies detected.'**
  String anomaliesDetected(int count);

  /// No description provided for @measurementsAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'{count} measurements analyzed.'**
  String measurementsAnalyzed(int count);

  /// No description provided for @latestAnomaly.
  ///
  /// In en, this message translates to:
  /// **'Latest Anomaly'**
  String get latestAnomaly;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Anomaly Analysis'**
  String get aiAnalysis;

  /// No description provided for @aiAnalysisLoading.
  ///
  /// In en, this message translates to:
  /// **'AI analysis is loading...'**
  String get aiAnalysisLoading;

  /// No description provided for @possibleCause.
  ///
  /// In en, this message translates to:
  /// **'Possible Cause'**
  String get possibleCause;

  /// No description provided for @affectedSensors.
  ///
  /// In en, this message translates to:
  /// **'Affected Sensors'**
  String get affectedSensors;

  /// No description provided for @anomalyHistory.
  ///
  /// In en, this message translates to:
  /// **'Anomaly History'**
  String get anomalyHistory;

  /// No description provided for @detectedAnomalies.
  ///
  /// In en, this message translates to:
  /// **'Detected Anomalies'**
  String get detectedAnomalies;

  /// No description provided for @analyzedMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements Analyzed'**
  String get analyzedMeasurements;

  /// No description provided for @unusualValuesDetected.
  ///
  /// In en, this message translates to:
  /// **'Unusual values detected in {count} sensors.'**
  String unusualValuesDetected(int count);

  /// No description provided for @connectionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get connectionChecking;

  /// No description provided for @deviceStale.
  ///
  /// In en, this message translates to:
  /// **'Data outdated'**
  String get deviceStale;

  /// No description provided for @serverUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable'**
  String get serverUnavailable;

  /// No description provided for @sensorDataError.
  ///
  /// In en, this message translates to:
  /// **'Data error'**
  String get sensorDataError;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @loginFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password.'**
  String get loginFieldsRequired;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection.'**
  String get loginNetworkError;

  /// No description provided for @loginTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get loginTooManyRequests;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get loginFailed;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your sensors.'**
  String get loginSubtitle;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign out. Please try again.'**
  String get signOutFailed;

  /// No description provided for @serverConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to server…'**
  String get serverConnecting;

  /// No description provided for @aiAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load AI analysis. Please try again later.'**
  String get aiAnalysisFailed;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @adminDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get adminDevices;

  /// No description provided for @demoLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demoLabel;

  /// No description provided for @demoDeviceNotice.
  ///
  /// In en, this message translates to:
  /// **'This screen displays sample readings. No live device is connected.'**
  String get demoDeviceNotice;

  /// No description provided for @realDevices.
  ///
  /// In en, this message translates to:
  /// **'Real devices'**
  String get realDevices;

  /// No description provided for @recentDeviceData.
  ///
  /// In en, this message translates to:
  /// **'Recent readings'**
  String get recentDeviceData;

  /// No description provided for @demoDevices.
  ///
  /// In en, this message translates to:
  /// **'Demo devices'**
  String get demoDevices;

  /// No description provided for @demoExcludedFromSummary.
  ///
  /// In en, this message translates to:
  /// **'Demo devices are excluded from the status counts above.'**
  String get demoExcludedFromSummary;

  /// No description provided for @latestAnalysisResults.
  ///
  /// In en, this message translates to:
  /// **'Latest analysis results'**
  String get latestAnalysisResults;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshData;

  /// No description provided for @anomalyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load analysis results. Use Refresh to try again.'**
  String get anomalyLoadFailed;

  /// No description provided for @latestAnalysisNotice.
  ///
  /// In en, this message translates to:
  /// **'Only anomalies in the latest batch of readings are shown. This is not a permanent anomaly history.'**
  String get latestAnalysisNotice;

  /// No description provided for @measurementValue.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get measurementValue;

  /// No description provided for @baselineMedian.
  ///
  /// In en, this message translates to:
  /// **'Baseline median'**
  String get baselineMedian;

  /// No description provided for @analyzeWithAi.
  ///
  /// In en, this message translates to:
  /// **'Analyze with AI'**
  String get analyzeWithAi;

  /// No description provided for @aiResultsScope.
  ///
  /// In en, this message translates to:
  /// **'The list shows up to the last 10 anomalies used for the AI interpretation. Cached results may be used.'**
  String get aiResultsScope;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
