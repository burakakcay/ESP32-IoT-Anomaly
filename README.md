# Sentinel — ESP32 IoT Anomali İzleme Sistemi

Sentinel; ESP32 üzerinde çalışan sıcaklık, nem, ivme ve jiroskop sensörlerinden veri toplayan, ölçümleri Cloud Firestore'da saklayan, Robust Z-score yöntemiyle anomali analizi yapan ve sonuçları Flutter mobil uygulaması ile web yönetim panelinde görselleştiren bir IoT izleme sistemidir.

- Web paneli: https://esp32-iot-anomali.web.app
- Backend: https://sentinel-backend-s3yl.onrender.com

Panel ve korumalı API uç noktaları yetkili Firebase kullanıcısıyla oturum açılmasını gerektirir.

## Özellikler

- DHT22 ile sıcaklık ve nem ölçümü
- MPU6050 ile üç eksenli ivme ve jiroskop ölçümü
- Ölçümlerin 15 saniyede bir Cloud Firestore'a gönderilmesi
- Wi-Fi bağlantısı kesildiğinde kontrollü yeniden bağlanma
- NTP ile zaman senkronizasyonu
- Son 240 ölçümün yaklaşık bir saatlik grafik geçmişi olarak gösterilmesi
- Sıcaklık, nem, ivme ve jiroskop için sabit ve karşılaştırılabilir grafik ölçekleri
- Grafik noktalarında değer, eksen ve ölçüm zamanı gösterimi
- Son 60 ölçüm üzerinden Robust Z-score anomali analizi
- İlk 20 ölçümün referans, sonraki 40 ölçümün analiz verisi olarak kullanılması
- Gemini ile isteğe bağlı yapay zekâ destekli anomali yorumu
- ESP32 çevrimdışı olduğunda son Firestore verilerinin gösterilmeye devam etmesi
- Türkçe ve İngilizce mobil uygulama desteği
- Firebase Authentication ile e-posta/parola girişi ve API'de kullanıcı UID kontrolü
- Web yönetim panelinde genel özet, cihaz detayları ve üç etiketli demo cihaz
- Son analiz ve kalıcı geçmiş için ayrı sekmeler
- Anomalilerin ölçüm kimliğine göre tekrar oluşturulmadan Firestore'a kaydedilmesi
- Kaydedilmiş en yeni 100 anomalinin ölçüm detaylarıyla görüntülenmesi

## Sistem Mimarisi

```mermaid
flowchart LR
    DHT["DHT22<br/>Sıcaklık ve nem"] --> ESP["ESP32 firmware"]
    MPU["MPU6050<br/>İvme ve jiroskop"] --> ESP
    ESP -->|"15 saniyede bir"| FS["Cloud Firestore"]
    FS --> API["Node.js ve Express API"]
    API --> AN["Robust Z-score analizi"]
    AN --> AI["Gemini analizi<br/>(isteğe bağlı)"]
    API --> APP["Flutter mobil uygulaması"]
    API --> WEB["Flutter web yönetim paneli"]
    AN -->|"Tespit edilen anomaliler"| FS
```

Veri akışı:

1. ESP32 sensörleri okur ve ölçüme yerel bir zaman damgası ekler.
2. Ölçüm `devices/{deviceId}/readings` koleksiyonuna yazılır.
3. Node.js backend, Firestore verilerini mobil uygulamaya REST API üzerinden sunar.
4. Mobil uygulama açılışta son 240 ölçümü yükler ve grafiklerde eski → yeni sırasıyla gösterir.
5. Anomali analizi aynı sorgudaki en yeni 60 ölçüm üzerinden yapılır.
6. Uygulama açıkken en güncel ölçüm 15 saniyede bir yenilenir.
7. Çalıştırılan analizlerde bulunan anomaliler `devices/{deviceId}/anomalies/{readingId}` yoluna kaydedilir.
8. Kalıcı geçmiş ekranı kayıtları API üzerinden okur; yeni analiz veya Gemini çağrısı başlatmaz.

## Kullanılan Teknolojiler

| Katman | Teknolojiler |
|---|---|
| Donanım | ESP32, DHT22, MPU6050 |
| Firmware | Arduino, PlatformIO, FirebaseClient |
| Veritabanı | Google Cloud Firestore |
| Backend | Node.js, Express, Firebase Admin SDK |
| Anomali analizi | Robust Z-score, medyan ve MAD |
| Yapay zekâ | Google Gemini API |
| Mobil uygulama | Flutter, Dart, `fl_chart` |
| Web paneli | Flutter Web, Firebase Hosting |
| Kimlik doğrulama | Firebase Authentication, Firebase ID token |
| Backend yayını | Render |
| Yerelleştirme | Flutter localization, Türkçe ve İngilizce |

## Proje Yapısı

```text
ESP32-IoT-Anomaly/
├── backend/                  # REST API ve anomali analizi
│   ├── index.js
│   ├── anomalyDetector.js
│   ├── config/
│   ├── middleware/
│   ├── repositories/
│   ├── routes/
│   ├── services/
│   ├── test/
│   └── package.json
├── firmware/                 # ESP32 PlatformIO projesi
│   ├── include/
│   ├── src/main.cpp
│   └── platformio.ini
├── mobile_app/               # Flutter mobil uygulaması ve web paneli
│   ├── assets/
│   ├── lib/
│   │   ├── core/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── test/
│   ├── web/
│   ├── firebase.json
│   └── pubspec.yaml
└── README.md
```

## Firestore Veri Yapısı

Ölçümler aşağıdaki belge yolunda tutulur:

```text
devices/{deviceId}/readings/{readingId}
```

Örnek ölçüm belgesi:

```json
{
  "device_id": "ESP32_Sensor_Node_001",
  "timestamp": "2026-08-14T00:52:13",
  "temperature": 29.5,
  "humidity": 44.8,
  "accel_x": 17068,
  "accel_y": 196,
  "accel_z": -1604,
  "gyro_x": -344,
  "gyro_y": -166,
  "gyro_z": 204
}
```

## Anomali Analizi

### Son ölçümlerin analizi

Backend, son 60 ölçümü kronolojik sıraya çevirir. İlk 20 ölçüm referans kümesi olarak kullanılır; sonraki 40 ölçüm önceki verilerle karşılaştırılır.

Her sensör alanı için:

1. Referans değerlerin medyanı hesaplanır.
2. Medyandan mutlak sapmaların medyanı (MAD) hesaplanır.
3. Robust Z-score değeri hesaplanır:

```text
Robust Z-score = 0.6745 × (değer - medyan) / MAD
```

Mutlak Robust Z-score değeri `5` sınırını aşarsa ölçüm anomali olarak işaretlenir.

Her ölçüm, kendisinden önceki ölçümlerle karşılaştırılır; referans kümesi analiz boyunca büyür. MAD sıfır olduğunda mevcut uygulama Z-score değerini sıfır kabul eder. Analiz için en az 21 ölçüm gerekir.

### Kalıcı anomali geçmişi

Kayıt yolu: `devices/{deviceId}/anomalies/{readingId}`.

- Belge kimliği kaynak ölçüm kimliğidir. Aynı ölçüm tekrar analiz edilse de ikinci kayıt oluşturulmaz ve ilk kayıt değiştirilmez.
- `timestamp` ölçüm zamanını, `detectedAt` sunucudaki kayıt zamanını tutar. API, `detectedAt` değerini ISO 8601 metni olarak döndürür.
- Kayıtta `device_id`, `readingId`, `isAnomaly`, `anomalyCount` ve anomalili sensörlerin `measurements` detayları bulunur.
- Geçmiş, ölçüm zamanına göre yeniden eskiye sıralanan en fazla 100 kaydı getirir. `returnedCount` yalnızca bu yanıttaki kayıt sayısıdır.
- Analiz istek üzerine çalışır. Uygulama kapalıyken bütün ölçümlerin arka planda analiz edilmesi veya eski verilerin topluca taranması sağlanmaz.
- Son analiz önbelleği 10 saniye, AI yanıt önbelleği 60 saniyedir. Geçmişi okumak yeni analiz yapmaz; AI yorumu geçmiş belgelerine kaydedilmez.

## Kurulum

### Gereksinimler

- ESP32 geliştirme kartı
- DHT22 sıcaklık ve nem sensörü
- MPU6050 ivme ve jiroskop sensörü
- PlatformIO
- Node.js ve npm
- Flutter SDK ve Android geliştirme ortamı
- Firebase projesi ve Cloud Firestore veritabanı
- Firebase Authentication üzerinde etkin e-posta/parola sağlayıcısı
- Web yayını için Firebase CLI; Firebase uygulama yapılandırması için FlutterFire CLI
- Gemini analizi kullanılacaksa Gemini API anahtarı

### 1. Firmware yapılandırması

`firmware/include/secrets.h` dosyasını oluşturun:

```cpp
#pragma once

#define WIFI_SSID "WIFI_ADI"
#define WIFI_PASSWORD "WIFI_PAROLASI"

#define FIREBASE_PROJECT_ID "FIREBASE_PROJE_KIMLIGI"
#define FIREBASE_API_KEY "FIREBASE_API_ANAHTARI"
#define FIREBASE_USER_EMAIL "CIHAZ_KULLANICI_EPOSTASI"
#define FIREBASE_USER_PASSWORD "CIHAZ_KULLANICI_PAROLASI"

#define NTP_SERVER "pool.ntp.org"
#define TZ_INFO "TRT-3"
```

Bu dosya `.gitignore` kapsamındadır ve sürüm kontrolüne eklenmemelidir.

Firmware'i derleyin ve ESP32'ye yükleyin:

```powershell
cd firmware
pio run
pio run --target upload
pio device monitor
```

ESP32 ayrıca yerel ağ üzerinde `/sensor` HTTP uç noktasından son ölçümü JSON olarak sunar.

### 2. Backend yapılandırması

Bağımlılıkları yükleyin:

```powershell
cd backend
npm install
```

Firebase Console üzerinden bir servis hesabı anahtarı oluşturun ve dosyayı şu konuma yerleştirin:

```text
backend/serviceAccountKey.json
```

`backend/.env` dosyasını oluşturun. `ALLOWED_USER_UID`, Firebase Authentication'da panele giriş yapacak kullanıcının UID değeridir; ESP32 için kullanılan cihaz hesabından ayrı bir kullanıcı kullanın.

```env
PORT=3000
DEVICE_ID=ESP32_Sensor_Node_001
ALLOWED_USER_UID=YETKILI_KULLANICI_UID
# İsteğe bağlı: Gemini yorumu için
GEMINI_API_KEY=API_ANAHTARI
# İsteğe bağlı: varsayılan backend/serviceAccountKey.json yerine başka konum
# FIREBASE_SERVICE_ACCOUNT_PATH=C:/guvenli/konum/serviceAccountKey.json
```

Backend'i başlatın:

```powershell
npm start
```

API varsayılan olarak `http://localhost:3000` adresinde çalışır.

### 3. Flutter uygulaması

Uygulama `lib/firebase_options.dart` yapılandırmasıyla Firebase'e bağlanır. Kendi Firebase projenizi kullanıyorsanız Firebase CLI ile giriş yaptıktan sonra `mobile_app` klasöründe yapılandırmayı oluşturun:

```powershell
firebase login
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure --project=FIREBASE_PROJE_KIMLIGI --platforms=android,web --android-package-name=com.burakakcay.sentinel
```

`mobile_app/lib/core/constants/api_constants.dart` dosyası varsayılan olarak yayınlanan backend'i kullanır:

```dart
static const nodeBaseUrl = 'https://sentinel-backend-s3yl.onrender.com';
```

Ardından:

```powershell
cd mobile_app
flutter pub get
flutter gen-l10n
flutter run
```

Yerel backend kullanacaksanız adresi `http://BILGISAYAR_IP_ADRESI:3000` olarak değiştirin; telefonun bu bilgisayara ağ erişimi olmalıdır. Yayınlanan HTTPS backend için aynı ağ gerekmiyor.

Web panelini `mobile_app` klasöründe çalıştırın:

```powershell
flutter run -d chrome --web-port=5000
```

`backend/app.js` içindeki CORS listesi `http://localhost:5000` ve mevcut Firebase Hosting adreslerine izin verir. Başka bir web adresi kullanıldığında bu liste güncellenmelidir. Uygulamada oturum açan kullanıcının UID'si backend'deki `ALLOWED_USER_UID` ile eşleşmelidir.

### 4. Yayınlama

Backend için kullanılan Render yapılandırması:

| Alan | Değer |
|---|---|
| Root Directory | `backend` |
| Build Command | `npm ci` |
| Start Command | `npm start` |
| Health Check Path | `/health` |
| Build Filter / Included Paths | `backend/**` |

Render ortamında `DEVICE_ID`, `ALLOWED_USER_UID` ve isteğe bağlı `GEMINI_API_KEY` tanımlanır. Servis hesabı `serviceAccountKey.json` adlı secret file olarak eklenir; `FIREBASE_SERVICE_ACCOUNT_PATH=/etc/secrets/serviceAccountKey.json` ayarlanır. Backend Render'ın sağladığı `PORT` değerini kullanır.

Web panelini yayınlamak için `mobile_app` klasöründe:

```powershell
flutter build web --release
firebase deploy --only hosting --project=esp32-iot-anomali
```

`firebase.json`, Hosting için `build/web` dizinini ve tek sayfa uygulama yönlendirmesini kullanır. Kendi projenizde proje kimliğini değiştirin. Her web değişikliğinde deploy öncesi yeniden build alınmalıdır. Eski arayüz görünürse tarayıcı önbelleğini devre dışı bırakıp yeniden yükleyin.

## REST API

| Yöntem | Uç nokta | Açıklama |
|---|---|---|
| `GET` | `/health` | Kimlik doğrulaması gerektirmeyen servis sağlık yanıtı. |
| `GET` | `/api/dashboard` | Grafik için son 240 ölçümü ve son 60 ölçümden üretilen anomali sonucunu döndürür. |
| `GET` | `/api/readings` | Son 60 ölçümü döndürür. |
| `GET` | `/api/readings/latest` | En güncel ölçümü döndürür. |
| `GET` | `/api/anomalies` | Son 60 ölçümün anomali analizini döndürür. |
| `GET` | `/api/anomalies/ai` | Anomaliler için Gemini yorumunu döndürür. |
| `GET` | `/api/anomalies/history` | Kaydedilmiş en yeni 100 anomalinin geçmişini döndürür. |

Tüm `/api/*` isteklerinde `Authorization: Bearer <Firebase ID token>` başlığı gerekir. Eksik/geçersiz token `401`, farklı kullanıcı UID'si `403`, yapılandırılmamış `ALLOWED_USER_UID` ise geçerli token sonrasında `503` döndürür. Flutter API servisi token'ı oturumdan alıp otomatik ekler.

Örnek kontrol:

```powershell
$headers = @{ Authorization = "Bearer GECERLI_FIREBASE_ID_TOKEN" }
$dashboard = Invoke-RestMethod -Uri "http://localhost:3000/api/dashboard" -Headers $headers
$dashboard.readings.Count
$dashboard.anomalies.analyzedReadings
```

Beklenen sonuçlar sırasıyla `240` ve `40` değerleridir. Firestore'da 240'tan az belge varsa ölçüm sayısı daha düşük olabilir.

## Mobil Uygulama Davranışı

- Uygulama açıldığında son 240 ölçüm yüklenir.
- Grafikler yaklaşık bir saatlik geçmişi gösterir.
- Sıcaklık, nem, ivme ve jiroskop grafiklerinde ölçüm noktasına dokunulduğunda zaman ve değer gösterilir.
- ESP32'den yeni veri gelmezse son ölçümler ekranda kalır.
- Son ölçüm 45 saniyeden eskiyse cihaz `Veri güncel değil` olarak işaretlenir. Bu durum backend'e ulaşılamamasından ayrı gösterilir.
- Backend kapalıysa mobil uygulama Firestore verilerini alamaz.
- Uygulama açıkken en yeni ölçüm 15 saniyede bir sorgulanır.
- Bellekte en fazla 240 ölçüm tutulur; sınır aşıldığında en eski ölçüm kaldırılır.

## Doğrulama

Aşağıdaki komutlar, her bileşenin kendi klasöründe çalıştırılır.

Firmware:

```powershell
cd firmware
pio run
```

Backend:

```powershell
cd backend
node --check index.js
npm test
```

Flutter:

```powershell
cd mobile_app
flutter analyze
flutter test
```

Manuel test akışı:

1. Backend'i başlatın.
2. Mobil uygulamayı tamamen kapatıp yeniden açın.
3. Grafiklerin geçmiş 240 ölçümle dolduğunu kontrol edin.
4. ESP32'yi bağlayın ve yeni ölçümlerin 15 saniyede bir geldiğini doğrulayın.
5. ESP32'nin bağlantısını kesin.
6. Yaklaşık 45–60 saniye içinde durumun `Veri güncel değil` olarak değiştiğini doğrulayın.
7. Eski ölçümlerin ve grafiklerin ekranda kalmaya devam ettiğini kontrol edin.
8. Web panelinde son analiz ve kalıcı geçmiş sekmelerini açın; tarih sırasını ve genişletilen ölçüm detaylarını kontrol edin.
9. Yeni ölçüm yokken analizi tekrar çalıştırın; Firestore'daki aynı ölçümlerin anomali kayıt sayısının artmadığını doğrulayın.
10. AI yorumunu ve oturum kapatma işlemini kontrol edin. Tokensiz bir `/api/*` isteğinin `401` döndürdüğünü doğrulayın.

## Web Yönetim Paneli

- Genel bakış, gerçek cihazların güncellik durumlarını özetler. Demo cihazlar gerçek cihaz sayaçlarına katılmaz.
- Cihazlar bölümünden gerçek ESP32'nin ölçümleri ve üç demo cihazın temsili verileri açılır. Demo verileri fiziksel cihazlardan gelmez.
- Son analiz bölümünde son ölçüm grubunun sonuçları ve isteğe bağlı AI yorumu yer alır.
- Kalıcı geçmiş bölümünde kaydedilmiş en yeni 100 anomali listelenir. Tarih/cihaz filtresi ve sayfalama henüz yoktur.
- Sol menüde oturum kapatma bulunur. Tarayıcı ve menü logoları `assets/icons/sentinel_monochrome_clean.svg` kaynağından hazırlanmıştır.

## Güvenlik

- `firmware/include/secrets.h`, `backend/.env` ve `backend/serviceAccountKey.json` dosyaları sürüm kontrolüne eklenmemelidir.
- Gerçek Wi-Fi parolaları, Firebase kullanıcı bilgileri, servis hesabı anahtarları ve Gemini API anahtarları README veya kaynak kod içine yazılmamalıdır.
- Bir anahtar yanlışlıkla herkese açık bir depoya gönderilirse yalnızca dosyayı silmek yeterli değildir; ilgili anahtar veya parola yenilenmelidir.

## Bilinen Sınırlamalar

- Backend ve mobil uygulama tek bir `DEVICE_ID` değeri için yapılandırılmıştır.
- API erişimi tek bir `ALLOWED_USER_UID` ile sınırlandırılır; çok kullanıcılı rol/yetki yönetimi bulunmaz.
- Anomali geçmişi istek üzerine yapılan analizlerden oluşur; kesintisiz arka plan analizi veya eksiksiz geçmiş taraması değildir.
- Ölçüm zamanları saat dilimi içermeyen metinlerdir; farklı saat dilimlerindeki istemcilerde zaman yorumlaması sınırlıdır.
- Mobil uygulama Firestore'a doğrudan bağlanmaz; Node.js backend'in çalışıyor olması gerekir.
- Sabit grafik aralıklarının dışına çıkan değerler grafik sınırında kırpılabilir.
- Anomali tespiti prototip amaçlı istatistiksel bir yöntemdir ve kesin arıza teşhisi olarak değerlendirilmemelidir.
- Gemini analizi isteğe bağlıdır ve `GEMINI_API_KEY` olmadan kullanılamaz.

