# Sentinel — ESP32 IoT Anomali İzleme Sistemi

Sentinel; ESP32 ile sıcaklık, nem, ivme ve jiroskop verilerini toplayan, Node.js API üzerinden kaydeden ve Flutter arayüzünde gösteren bir IoT projesidir.

Yerel geliştirmede ölçümler SQLite'a kaydedilir. Kullanıcı girişi Firebase Authentication, kalıcı anomali geçmişi Cloud Firestore kullanır. Gemini destekli yorumlama isteğe bağlıdır.

## Özellikler

- DHT22 ve MPU6050 üzerinden sensör verisi toplama
- Uygun bağlantı koşullarında 5 saniyede bir ölçüm gönderimi
- Cihaz anahtarıyla API erişimi ve mükerrer kayıt kontrolü
- Geçici gönderim hatalarında artan bekleme süreleriyle tekrar deneme
- UTC ölçüm zamanı ve arayüzde yerel saat gösterimi
- Başarılı kalibrasyon sonrası jiroskop ofset düzeltmesi
- Dört sensör grafiğinde tarih filtresi, yakınlaştırma ve kaydırma
- Filtrelenmiş grafiklerde 30 saniyeden uzun veri boşluklarının gösterilmesi
- Y eksenini veriye uydurma seçeneği
- İvme için g, jiroskop için °/s gösterimi
- Veri güncelliği takibi ve Robust Z-score anomali analizi

## Veri Akışı

```text
ESP32 → HTTP API → SQLite → Flutter
                     │
                     └→ Anomali analizi → Firestore
                                       → Gemini (isteğe bağlı)
```

`READINGS_SOURCE` ayarı backend'in ölçümleri SQLite veya Firestore'dan okumasını belirler. ESP32'nin API üzerinden gönderdiği yeni ölçümler SQLite'a kaydedilir.

## Proje Yapısı

```text
firmware/     ESP32 ve PlatformIO kodları
backend/      Express API, SQLite ve anomali analizi
mobile_app/   Flutter mobil/web arayüzü
```

## Gereksinimler

- ESP32, DHT22 ve MPU6050
- PlatformIO
- Node.js 24 ve npm
- Projenin SDK gereksinimini karşılayan Flutter SDK ve Chrome
- Firebase projesi, Authentication ve Firestore yapılandırması

## Yerel Kurulum

### 1. Backend

Firebase servis hesabı dosyasını `backend/serviceAccountKey.json` konumuna yerleştirin. `backend/.env` dosyasını oluşturun:

```env
PORT=3000
DEVICE_ID=ESP32_Sensor_Node_001
READINGS_SOURCE=sqlite
ALLOWED_USER_UID=FIREBASE_KULLANICI_UID
DEVICE_API_KEY=64_HEX_KARAKTERLIK_CIHAZ_ANAHTARI
# İsteğe bağlı:
# GEMINI_API_KEY=GEMINI_ANAHTARI
```

`DEVICE_API_KEY` için yer tutucu yerine 64 hexadecimal karakterlik bir anahtar kullanılmalıdır.

```powershell
cd backend
npm install
npm start
```

API `http://localhost:3000` adresinde çalışır. SQLite dosyası otomatik olarak `backend/data/sentinel.sqlite` konumunda oluşturulur.

### 2. ESP32

`firmware/include/secrets.h` içindeki Wi-Fi ve zaman ayarlarını yapılandırın. API ayarlarını ekleyin:

```cpp
#define SENTINEL_API_URL "http://BILGISAYAR_IP_ADRESI:3000/api/readings"
#define SENTINEL_API_KEY "BACKEND_ILE_AYNI_CIHAZ_ANAHTARI"
```

ESP32, bilgisayarın yerel IP adresine erişebilmelidir. Burada `localhost` kullanılmaz. Bilgisayarın IP adresi değişirse ayarı güncelleyip yeniden yükleyin.

```powershell
cd firmware
pio run --target upload
pio device monitor
```

Başlangıç kalibrasyonu boyunca sensörü sabit tutun.

### 3. Flutter

`mobile_app/lib/firebase_options.dart` dosyasının kullanılacak Firebase projesi için yapılandırılmış olması gerekir. Oturum açan kullanıcının UID'si backend'deki `ALLOWED_USER_UID` ile eşleşmelidir.

```powershell
cd mobile_app
flutter pub get
flutter gen-l10n
flutter run -d chrome --web-port=5000 --dart-define=API_BASE_URL=http://localhost:3000
```

Backend terminali açık kalmalıdır. Yerel CORS ayarı `http://localhost:5000` adresine izin verir.

Fiziksel telefonda çalıştırılırken API adresinde `localhost` yerine bilgisayarın erişilebilir yerel IP adresi kullanılmalıdır.

## API

| Yöntem | Yol | İşlev |
|---|---|---|
| GET | `/health` | Servis sağlık kontrolü |
| POST | `/api/readings` | Cihaz ölçümünü kaydetme |
| GET | `/api/readings` | Son ölçümler |
| GET | `/api/readings/latest` | En yeni ölçüm |
| GET | `/api/readings/history?fromMs=...&toMs=...` | Tarih aralığındaki ölçümler |
| GET | `/api/dashboard` | Ölçümler ve anomali sonucu |
| GET | `/api/anomalies` | Anomali analizi |
| GET | `/api/anomalies/ai` | İsteğe bağlı Gemini yorumu |
| GET | `/api/anomalies/history` | Kalıcı anomali geçmişi |

Ölçüm gönderimi cihaz anahtarını, korumalı GET istekleri Firebase ID token'ını `Authorization: Bearer ...` başlığında kullanır. `/health` herkese açıktır.

Tarih aralığı sorgusu SQLite gerektirir; başlangıç dahil, bitiş hariçtir ve en fazla 10.000 kayıt döndürür.

## Uygulama Davranışı

- Açılışta son 240 ölçüm yüklenir; güncel ölçüm 15 saniyede bir sorgulanır.
- Son ölçüm 45 saniyeden eskiyse “Veri güncel değil” gösterilir.
- Tarih filtresi backend'den ayrıca geçmiş kayıtları getirir.
- Jiroskop düzeltmesi yalnızca yeni kayıtlara uygulanır; eski veriler değişmez.
- Anomali analizi son 60 ölçümü kullanır. İlk 20 ölçüm başlangıç referansıdır; analiz için en az 21 ölçüm gerekir.

## Kontroller

İlgili bileşenin klasöründe çalıştırın:

```powershell
# firmware
pio run

# backend
npm test

# mobile_app
flutter analyze
flutter test
```

Elle kontrol: veri gönderimi, ESP32 bağlantısının kesilip geri gelmesi, boş tarih aralığı, grafik yakınlaştırma/sıfırlama ve Y ekseni seçeneği.

## Sınırlamalar ve Güvenlik

- Sistem tek cihaz ve tek yetkili kullanıcı için yapılandırılmıştır.
- SQLite kullanılsa da Firebase bağımlılıkları devam eder.
- Bekleyen gönderim RAM'dedir; kalıcı çevrimdışı ölçüm kuyruğu yoktur.
- Geçerli zaman elde edilmeden ölçüm gönderilmez.
- Firmware'in mevcut API gönderimi yerel HTTP içindir.
- Anomali analizi istek üzerine çalışır ve kesin arıza teşhisi sağlamaz.
- `.env`, `secrets.h`, servis hesabı dosyaları ve gerçek anahtarlar sürüm kontrolüne eklenmemelidir.