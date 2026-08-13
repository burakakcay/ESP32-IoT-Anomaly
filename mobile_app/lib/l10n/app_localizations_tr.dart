// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Sentinel';

  @override
  String get device => 'Cihaz';

  @override
  String get connected => 'Bağlı';

  @override
  String get connecting => 'Bağlanıyor';

  @override
  String get disconnected => 'Bağlantı Kesildi';

  @override
  String get lastUpdate => 'Son Güncelleme';

  @override
  String get packets => 'Alınan Paket';

  @override
  String get temperature => 'Sıcaklık';

  @override
  String get humidity => 'Nem';

  @override
  String get acceleration => 'İvme';

  @override
  String get gyroscope => 'Jiroskop';

  @override
  String get normal => 'Normal';

  @override
  String get warning => 'Uyarı';

  @override
  String get high => 'Yüksek';

  @override
  String get critical => 'Kritik';

  @override
  String get minimum => 'Min';

  @override
  String get average => 'Ortalama';

  @override
  String get maximum => 'Maks';

  @override
  String get noData => 'Veri bulunamadı';

  @override
  String get anomalyStatus => 'Anomali Durumu';

  @override
  String get anomalyDataLoading => 'Anomali verileri yükleniyor...';

  @override
  String get systemNormal => 'Sistem normal. Anomali tespit edilemedi.';

  @override
  String anomaliesDetected(int count) {
    return '$count anomali tespit edildi.';
  }

  @override
  String measurementsAnalyzed(int count) {
    return '$count ölçüm analiz edildi.';
  }

  @override
  String get latestAnomaly => 'Son Anomali';
}
