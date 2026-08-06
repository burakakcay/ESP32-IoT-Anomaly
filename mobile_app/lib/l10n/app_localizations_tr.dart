// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get device => 'Cihaz';

  @override
  String get lastUpdate => 'Son Güncelleme';

  @override
  String get connected => 'Bağlı';

  @override
  String get connecting => 'Bağlanıyor';

  @override
  String get disconnected => 'Bağlantı Kesildi';

  @override
  String get normal => 'Normal';

  @override
  String get warning => 'Uyarı';

  @override
  String get high => 'Yüksek';

  @override
  String get critical => 'Kritik';

  @override
  String get temperature => 'Sıcaklık';

  @override
  String get humidity => 'Nem';

  @override
  String get acceleration => 'İvme';

  @override
  String get gyroscope => 'Jiroskop';
}
