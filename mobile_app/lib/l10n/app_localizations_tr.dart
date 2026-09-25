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

  @override
  String get aiAnalysis => 'Yapay Zeka Anomali Yorumu';

  @override
  String get aiAnalysisLoading => 'Yapay zeka analizi yükleniyor...';

  @override
  String get possibleCause => 'Olası Neden';

  @override
  String get affectedSensors => 'Etkilenen Sensörler';

  @override
  String get anomalyHistory => 'Anomali Geçmişi';

  @override
  String get detectedAnomalies => 'Tespit Edilen Anomali';

  @override
  String get analyzedMeasurements => 'İncelenen Ölçüm';

  @override
  String unusualValuesDetected(int count) {
    return '$count sensörde olağan dışı değer tespit edildi.';
  }

  @override
  String get connectionChecking => 'Kontrol ediliyor';

  @override
  String get deviceStale => 'Veri güncel değil';

  @override
  String get serverUnavailable => 'Sunucuya ulaşılamıyor';

  @override
  String get sensorDataError => 'Veri hatası';

  @override
  String get loginTitle => 'Oturum aç';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get passwordLabel => 'Parola';

  @override
  String get signInButton => 'Giriş yap';

  @override
  String get signingIn => 'Giriş yapılıyor…';

  @override
  String get loginFieldsRequired => 'E-posta ve parolanızı girin.';

  @override
  String get loginInvalidCredentials => 'E-posta veya parola hatalı.';

  @override
  String get loginNetworkError => 'İnternet bağlantınızı kontrol edin.';

  @override
  String get loginTooManyRequests =>
      'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.';

  @override
  String get loginFailed => 'Giriş yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get signOutButton => 'Çıkış yap';

  @override
  String get loginSubtitle => 'Sensörlerini takip et.';

  @override
  String get showPassword => 'Parolayı göster';

  @override
  String get hidePassword => 'Parolayı gizle';

  @override
  String get signOutFailed => 'Çıkış yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get serverConnecting => 'Sunucuya bağlanılıyor…';

  @override
  String get aiAnalysisFailed =>
      'Yapay zeka analizi alınamadı. Daha sonra tekrar deneyin.';

  @override
  String get adminOverview => 'Genel Bakış';

  @override
  String get adminDevices => 'Cihazlar';

  @override
  String get demoLabel => 'Demo';

  @override
  String get demoDeviceNotice =>
      'Bu ekran örnek ölçümleri gösterir. Canlı cihaz bağlantısı yoktur.';

  @override
  String get realDevices => 'Gerçek cihazlar';

  @override
  String get recentDeviceData => 'Verisi güncel';

  @override
  String get demoDevices => 'Demo cihazlar';

  @override
  String get demoExcludedFromSummary =>
      'Demo cihazlar yukarıdaki durum sayılarına dahil edilmez.';

  @override
  String get latestAnalysisResults => 'Son analiz sonuçları';

  @override
  String get refreshData => 'Yenile';

  @override
  String get anomalyLoadFailed =>
      'Analiz sonuçları alınamadı. Yenile düğmesiyle tekrar deneyebilirsiniz.';

  @override
  String get latestAnalysisNotice =>
      'Yalnızca son ölçüm grubundaki anomaliler gösterilir. Bu liste kalıcı anomali geçmişi değildir.';

  @override
  String get measurementValue => 'Ölçüm';

  @override
  String get baselineMedian => 'Referans medyan';

  @override
  String get analyzeWithAi => 'AI ile yorumla';

  @override
  String get aiResultsScope =>
      'Liste, AI yorumuna kaynak olan en fazla son 10 anomaliyi gösterir. Önbellekteki sonuç kullanılabilir.';
}
