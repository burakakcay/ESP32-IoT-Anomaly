#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <time.h>
#include <WebServer.h>

DHT dht(5, DHT22); // DHT22 sensörünün bağlı olduğu GPIO pini
MPU6050 mpu;
WebServer server(80);

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
String createSensorJson();
void handleSensor();
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

        Serial.print("ESP32 IP Adresi: ");
        Serial.println(WiFi.localIP());

        server.on("/sensor", HTTP_GET, handleSensor);

        server.begin();

        Serial.println("HTTP sunucusu başlatıldı.");
    }
    else
    {
        Serial.println("{\"status\":\"wifi_connection_failed\"}");
    }
}

void loop()

{
    server.handleClient();

    resyncTimeIfNeeded();

    Serial.println(createSensorJson());

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

String createSensorJson()
{
    float sicaklik = dht.readTemperature();
    float nem = dht.readHumidity();

    int16_t ax, ay, az;
    int16_t gx, gy, gz;

    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    bool sicaklikGecerli = !isnan(sicaklik);
    bool nemGecerli = !isnan(nem);

    struct tm localTime;

    if (!getLocalTime(&localTime))
    {
        return "{\"status\":\"time_not_set\"}";
    }

    char isoTime[32];

    strftime(
        isoTime,
        sizeof(isoTime),
        "%Y-%m-%dT%H:%M:%S",
        &localTime);

    String json;

    json += "{";
    json += "\"device_id\":\"" + String(deviceId) + "\",";
    json += "\"zaman\":\"" + String(isoTime) + "\",";
    json += "\"sicaklik\":";
    json += sicaklikGecerli ? String(sicaklik, 2) : "null";
    json += ",";
    json += "\"nem\":";
    json += nemGecerli ? String(nem, 2) : "null";
    json += ",";
    json += "\"ivme\":{";
    json += "\"x\":" + String(ax) + ",";
    json += "\"y\":" + String(ay) + ",";
    json += "\"z\":" + String(az);
    json += "},";
    json += "\"jiro\":{";
    json += "\"x\":" + String(gx) + ",";
    json += "\"y\":" + String(gy) + ",";
    json += "\"z\":" + String(gz);
    json += "}";
    json += "}";

    return json;
}

void handleSensor()
{
    server.send(
        200,
        "application/json",
        createSensorJson());
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
