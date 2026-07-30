#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <time.h>

DHT dht(5, DHT22); // DHT22 sensörünün bağlı olduğu GPIO pini
MPU6050 mpu;

// NTP sunucusundan zamanı almak için WiFi bağlantısı ve zaman ayarları
const char *ssid = "TP-Link_560A";      // WiFi ağınızın SSID'si
const char *password = "Ba21170341.";   // WiFi ağınızın şifresi
const char *ntpServer = "pool.ntp.org"; // NTP sunucusu
const char *tzInfo = "TRT-3";           // Türkiye saat dilimi bilgisi

const uint32_t WIFI_TIMEOUT_MS = 15000;                          // WiFi bağlantısı için zaman aşımı süresi (15 saniye)
const uint32_t NTP_TIMEOUT_MS = 10000;                           // NTP sunucusundan zaman almak için zaman aşımı süresi (10 saniye)
const uint32_t RESYNC_INTERVAL_MS = 24UL * 60UL * 60UL * 1000UL; // NTP zamanını yeniden senkronize etmek için aralık (24 saat)

const char deviceId[] = "ESP32_Sensor_Node_001"; // Cihaz kimliği

// Fonksiyon prototipleri
bool connectWifi();
void disconnectWifi();
bool syncTimeFromNTP();
void resyncTimeIfNeeded();

void setup()
{
    Serial.begin(115200);

    // Sensörler başlatılıyor
    Wire.begin(21, 22); // I2C pinlerini tanımla (SDA: GPIO21, SCL: GPIO22);
    mpu.initialize();   // MPU6050 sensörünü başlat
    dht.begin();        // DHT sensörünü başlat

    if (mpu.testConnection() ? Serial.println("{\"status\":\"boot_ok\"}") : Serial.println("{\"status\":\"mpu_couldn't_initialize\"}"))
        ;

    delay(2000); // Sensörlerin stabil hale gelmesi için kısa bir gecikme

    if (connectWifi())
    {
        if (syncTimeFromNTP() ? Serial.println("{\"status\":\"wifi_connected_and_time_set\"}") : Serial.println("{\"status\":\"wifi_connected_but_time_not_set\"}"))
            ;
    }
    else
    {
        Serial.println("{\"status\":\"wifi_connection_failed\"}");
    }

    disconnectWifi(); // WiFi bağlantısını kes, artık internete ihtiyaç yok
}

void loop()
{

    float sicaklik = dht.readTemperature(); // Sıcaklık okuma
    float nem = dht.readHumidity();         // Nem okuma
    int16_t ax, ay, az;                     // İvme verilerini tutacak değişkenler
    int16_t gx, gy, gz;                     // Jiroskop verilerini tutacak değişkenler
    struct tm timeinfo;                     // Zaman bilgisi için yapı

    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz); // İvme ve jiroskop verilerini oku

    bool sicaklikGecerli = !isnan(sicaklik);
    bool nemGecerli = !isnan(nem);

    // Zamanın güncellenmesi gerekiyorsa NTP sunucusundan zamanı yeniden al
    resyncTimeIfNeeded();

    // Verileri JSON formatında seri porta yazdır
    if (getLocalTime(&timeinfo, 0))
    {
        time_t now = time(nullptr);
        struct tm localTime;
        localtime_r(&now, &localTime);
        char isoTime[32];
        strftime(isoTime, sizeof(isoTime), "%Y-%m-%dT%H:%M:%S", &localTime);

        Serial.printf("{\"device_id\":\"%s\",\"zaman\":\"%s\",\"sicaklik\":%s,\"nem\":%s,\"ivme\":{\"x\":%d,\"y\":%d,\"z\":%d},\"jiro\":{\"x\":%d,\"y\":%d,\"z\":%d}}\n",
                      deviceId,
                      isoTime,
                      sicaklikGecerli ? String(sicaklik).c_str() : "null",
                      nemGecerli ? String(nem).c_str() : "null",
                      ax, ay, az, gx, gy, gz);
    }
    else
        Serial.println("{\"status\":\"time_not_set\"}");

    delay(2000);
}

bool connectWifi()
{
    WiFi.mode(WIFI_STA); //
    WiFi.begin(ssid, password);
    uint32_t startAttemptTime = millis();

    while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < WIFI_TIMEOUT_MS)
    {
        delay(500);
        Serial.print(".");
    }

    Serial.println();
    return WiFi.status() == WL_CONNECTED;
}
 
void disconnectWifi()
{
    WiFi.disconnect(true, true);
    WiFi.mode(WIFI_OFF);
}

bool syncTimeFromNTP()
{
    configTime(0, 0, ntpServer);
    setenv("TZ", tzInfo, 1);
    tzset();
    uint32_t startAttemptTime = millis();
    struct tm timeinfo;

    while (millis() - startAttemptTime < NTP_TIMEOUT_MS)
    {
        if (getLocalTime(&timeinfo))
        {
            return true;
        }
        delay(500);
    }
    return false;
}

void resyncTimeIfNeeded()
{
    static uint32_t lastSyncTime = 0;

    // Zamanın yeniden senkronize edilmesi gereken süre geçtiyse NTP sunucusundan zamanı yeniden al
    if (millis() - lastSyncTime > RESYNC_INTERVAL_MS)
    {
        
        if (syncTimeFromNTP())
        {
            Serial.println("{\"status\":\"time_resynced\"}");
            lastSyncTime = millis();
        }
        else
        {
            Serial.println("{\"status\":\"time_resync_failed\"}");
        }
    }
}
