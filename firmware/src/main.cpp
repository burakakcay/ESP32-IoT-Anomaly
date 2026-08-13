#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <time.h>
#include <WebServer.h>
#include "secrets.h"

#define ENABLE_USER_AUTH
#define ENABLE_FIRESTORE

#include <FirebaseClient.h>
#include "ExampleFunctions.h"

struct SensorReading
{
    // DHT22 ölçümleri
    float temperature;
    float humidity;

    // MPU6050 ham ivme ve jiroskop ölçümleri
    int16_t accelX;
    int16_t accelY;
    int16_t accelZ;

    int16_t gyroX;
    int16_t gyroY;
    int16_t gyroZ;

    // Aynı ölçüm çevrimine ait zaman bilgisi
    String timestamp;
    bool hasValidTime;
};

// Fonksiyon prototipleri
bool connectWifi();
void processFirestoreResult(AsyncResult &aResult);
SensorReading readSensorData();
void createSensorDocument(const SensorReading &reading);
String createSensorJson(const SensorReading &reading);
void handleSensor();
bool syncTimeFromNTP();
void resyncTimeIfNeeded();
void startNetworkServices();
void reconnectWifiIfNeeded();

DHT dht(5, DHT22); // DHT22 sensörünün bağlı olduğu GPIO pini
MPU6050 mpu;
WebServer server(80);

FirebaseApp app;
Firestore::Documents Docs;

const uint32_t WIFI_TIMEOUT_MS = 15000;                          // WiFi bağlantısı için zaman aşımı süresi (15 saniye)
const uint32_t NTP_TIMEOUT_MS = 10000;                           // NTP sunucusundan zaman almak için zaman aşımı süresi (10 saniye)
const uint32_t RESYNC_INTERVAL_MS = 24UL * 60UL * 60UL * 1000UL; // NTP zamanını yeniden senkronize etmek için aralık (24 saat)

const char deviceId[] = "ESP32_Sensor_Node_001"; // Cihaz kimliği

SSL_CLIENT ssl_client;

using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);

UserAuth user_auth(
    FIREBASE_API_KEY,
    FIREBASE_USER_EMAIL,
    FIREBASE_USER_PASSWORD,
    3000);

// Kimlik doğrulama mesajını yalnızca bir kez yazdırmak için kullanılır.
bool firebaseReady = false;

// HTTP sunucusu ve Firebase istemcisi başarıyla başlatıldıktan sonra true olur.
bool networkServicesStarted = false;

// Periyodik Firestore gönderimi ve Wi-Fi yeniden bağlanma zamanlayıcıları.
unsigned long lastFirestoreSend = 0;
unsigned long lastWifiReconnectAttempt = 0;

// Firestore kotasını korumak için sensör verisi 15 saniyede bir gönderilir.
const unsigned long FIRESTORE_INTERVAL = 15000;
const unsigned long WIFI_RETRY_INTERVAL = 30000;

// ============================================================
// ESP32 yaşam döngüsü
// ============================================================

void setup()
{
    Serial.begin(115200);

    // Sensörler başlatılıyor.
    Wire.begin(21, 22); // I2C pinlerini tanımla (SDA: GPIO21, SCL: GPIO22);
    mpu.initialize();   // MPU6050 sensörünü başlat
    dht.begin();        // DHT sensörünü başlat

    // MPU6050 bağlantısını başlangıçta doğrula.
    if (mpu.testConnection() ? Serial.println("{\"status\":\"boot_ok\"}") : Serial.println("{\"status\":\"mpu_couldn't_initialize\"}"))
        ;

    delay(2000); // Sensörlerin stabil hale gelmesi için kısa bir gecikme

    if (connectWifi())
    {
        startNetworkServices();
    }
    else
    {
        Serial.println("{\"status\":\"wifi_connection_failed\"}");
    }
}

void loop()
{
    // Wi-Fi koparsa kontrollü aralıklarla yeniden bağlanmayı dene.
    reconnectWifiIfNeeded();

    if (networkServicesStarted)
    {
        server.handleClient();
        app.loop();
    }

    // Firebase kimlik doğrulamasının tamamlandığını bir kez bildir.
    if (app.ready() && !firebaseReady)
    {
        firebaseReady = true;

        Serial.println("================================");
        Serial.println("Firebase authentication başarılı!");
        Serial.print("UID: ");
        Serial.println(app.getUid());
        Serial.println("================================");
    }

    resyncTimeIfNeeded();

    // Ağ, Firebase ve zaman hazırsa tek bir ölçüm snapshot'ını Firestore'a yaz.
    if (
        networkServicesStarted &&
        WiFi.status() == WL_CONNECTED &&
        app.ready() &&
        millis() - lastFirestoreSend >= FIRESTORE_INTERVAL)
    {
        lastFirestoreSend = millis();

        SensorReading reading = readSensorData();

        if (!reading.hasValidTime)
        {
            Serial.println("{\"status\":\"time_not_set\"}");
            return;
        }

        Serial.println(createSensorJson(reading));

        createSensorDocument(reading);
    }
}

// ============================================================
// Wi-Fi ve ağ servisleri
// ============================================================

bool connectWifi()
{
    WiFi.mode(WIFI_STA); //
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    uint32_t startAttemptTime = millis();

    while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < WIFI_TIMEOUT_MS)
    {
        delay(500);
        Serial.print(".");
    }

    Serial.println();
    return WiFi.status() == WL_CONNECTED;
}

// ============================================================
// Sensör okuma ve HTTP JSON yanıtı
// ============================================================

SensorReading readSensorData()
{
    SensorReading reading;

    // Her sensörü yalnızca bir kez oku; aynı snapshot hem JSON hem Firestore'da kullanılır.
    reading.temperature = dht.readTemperature();
    reading.humidity = dht.readHumidity();

    mpu.getMotion6(
        &reading.accelX,
        &reading.accelY,
        &reading.accelZ,
        &reading.gyroX,
        &reading.gyroY,
        &reading.gyroZ);

    struct tm localTime;

    // Zaman yoksa Firestore'a sıralanabilir/geçerli bir kayıt yazma.
    if (!getLocalTime(&localTime))
    {
        reading.hasValidTime = false;
        return reading;
    }

    char isoTime[32];

    strftime(
        isoTime,
        sizeof(isoTime),
        "%Y-%m-%dT%H:%M:%S",
        &localTime);

    reading.timestamp = String(isoTime);
    reading.hasValidTime = true;

    return reading;
}

void startNetworkServices()
{
    // Aynı servisleri ikinci kez başlatmayı önle.
    if (networkServicesStarted)
    {
        return;
    }

    set_ssl_client_insecure_and_buffer(ssl_client);

    Serial.println("Firebase başlatılıyor...");

    initializeApp(
        aClient,
        app,
        getAuth(user_auth),
        auth_debug_print,
        "firebaseAuthTask");

    app.getApp<Firestore::Documents>(Docs);

    if (syncTimeFromNTP())
    {
        Serial.println("{\"status\":\"wifi_connected_and_time_set\"}");
    }
    else
    {
        Serial.println("{\"status\":\"wifi_connected_but_time_not_set\"}");
    }

    // Yerel ağdaki hızlı tanılama/ölçüm görüntüleme endpoint'i.
    server.on("/sensor", HTTP_GET, handleSensor);
    server.begin();

    networkServicesStarted = true;

    Serial.print("ESP32 IP Adresi: ");
    Serial.println(WiFi.localIP());

    Serial.println("HTTP sunucusu başlatıldı.");
}

void reconnectWifiIfNeeded()
{
    if (WiFi.status() == WL_CONNECTED)
    {
        return;
    }

    // Başarısız bağlantılarda sürekli deneme yaparak işlemciyi/ağı yorma.
    if (millis() - lastWifiReconnectAttempt < WIFI_RETRY_INTERVAL)
    {
        return;
    }

    lastWifiReconnectAttempt = millis();

    Serial.println("{\"status\":\"wifi_reconnecting\"}");

    if (connectWifi())
    {
        Serial.println("{\"status\":\"wifi_reconnected\"}");

        if (!networkServicesStarted)
        {
            startNetworkServices();
        }
    }
    else
    {
        Serial.println("{\"status\":\"wifi_reconnect_failed\"}");
    }
}

String createSensorJson(const SensorReading &reading)
{
    const bool temperatureIsValid = !isnan(reading.temperature);
    const bool humidityIsValid = !isnan(reading.humidity);

    String json;

    json += "{";
    json += "\"device_id\":\"" + String(deviceId) + "\",";
    json += "\"zaman\":\"" + reading.timestamp + "\",";
    json += "\"sicaklik\":";
    json += temperatureIsValid ? String(reading.temperature, 2) : "null";
    json += ",";
    json += "\"nem\":";
    json += humidityIsValid ? String(reading.humidity, 2) : "null";
    json += ",";
    json += "\"ivme\":{";
    json += "\"x\":" + String(reading.accelX) + ",";
    json += "\"y\":" + String(reading.accelY) + ",";
    json += "\"z\":" + String(reading.accelZ);
    json += "},";
    json += "\"jiro\":{";
    json += "\"x\":" + String(reading.gyroX) + ",";
    json += "\"y\":" + String(reading.gyroY) + ",";
    json += "\"z\":" + String(reading.gyroZ);
    json += "}";
    json += "}";

    return json;
}

void handleSensor()
{
    // HTTP isteği için yeni ve tutarlı bir ölçüm snapshot'ı oluştur.
    SensorReading reading = readSensorData();

    if (!reading.hasValidTime)
    {
        server.send(
            503,
            "application/json",
            "{\"status\":\"time_not_set\"}");
        return;
    }

    server.send(
        200,
        "application/json",
        createSensorJson(reading));
}

// ============================================================
// Zaman senkronizasyonu
// ============================================================

bool syncTimeFromNTP()
{
    // Firestore'da sıralanabilir yerel zaman damgası üretmek için NTP kullanılır.
    configTime(0, 0, NTP_SERVER);
    setenv("TZ", TZ_INFO, 1);
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
    static uint32_t lastSyncAttempt = 0;

    if (millis() - lastSyncAttempt < RESYNC_INTERVAL_MS)
    {
        return;
    }

    lastSyncAttempt = millis();

    if (WiFi.status() != WL_CONNECTED)
    {
        Serial.println("{\"status\":\"time_resync_skipped_wifi_disconnected\"}");
        return;
    }

    if (syncTimeFromNTP())
    {
        Serial.println("{\"status\":\"time_resynced\"}");
    }
    else
    {
        Serial.println("{\"status\":\"time_resync_failed\"}");
    }
}

// ============================================================
// Firestore
// ============================================================

void createSensorDocument(const SensorReading &reading)
{
    if (!reading.hasValidTime)
    {
        Serial.println("Firestore: Zaman bilgisi alınamadı.");
        return;
    }

    // readings alt koleksiyonunda otomatik belge kimliği oluşturulur.
    String documentPath =
        "devices/" +
        String(deviceId) +
        "/readings";

    Values::StringValue deviceIdV(deviceId);
    Values::StringValue timestampV(reading.timestamp);

    Values::DoubleValue temperatureV(
        number_t(reading.temperature, 2));

    Values::DoubleValue humidityV(
        number_t(reading.humidity, 2));

    Values::IntegerValue accelXV(reading.accelX);
    Values::IntegerValue accelYV(reading.accelY);
    Values::IntegerValue accelZV(reading.accelZ);

    Values::IntegerValue gyroXV(reading.gyroX);
    Values::IntegerValue gyroYV(reading.gyroY);
    Values::IntegerValue gyroZV(reading.gyroZ);

    Document<Values::Value> doc(
        "device_id",
        Values::Value(deviceIdV));

    doc.add(
        "timestamp",
        Values::Value(timestampV));

    if (!isnan(reading.temperature))
    {
        doc.add(
            "temperature",
            Values::Value(temperatureV));
    }
    else
    {
        doc.add(
            "temperature",
            Values::Value(Values::NullValue()));
    }

    if (!isnan(reading.humidity))
    {
        doc.add(
            "humidity",
            Values::Value(humidityV));
    }
    else
    {
        doc.add(
            "humidity",
            Values::Value(Values::NullValue()));
    }

    doc.add(
        "accel_x",
        Values::Value(accelXV));

    doc.add(
        "accel_y",
        Values::Value(accelYV));

    doc.add(
        "accel_z",
        Values::Value(accelZV));

    doc.add(
        "gyro_x",
        Values::Value(gyroXV));

    doc.add(
        "gyro_y",
        Values::Value(gyroYV));

    doc.add(
        "gyro_z",
        Values::Value(gyroZV));

    Serial.println("Firestore: Sensor verisi gönderiliyor...");

    Docs.createDocument(
        aClient,
        Firestore::Parent(FIREBASE_PROJECT_ID),
        documentPath,
        DocumentMask(),
        doc,
        processFirestoreResult,
        "sensorDataTask");
}

void processFirestoreResult(AsyncResult &aResult)
{
    // FirebaseClient asenkron sonucu yoksa işlenecek bir durum da yoktur.
    if (!aResult.isResult())
        return;

    if (aResult.isEvent())
    {
        Firebase.printf(
            "Event task: %s, msg: %s, code: %d\n",
            aResult.uid().c_str(),
            aResult.eventLog().message().c_str(),
            aResult.eventLog().code());
    }

    if (aResult.isDebug())
    {
        Firebase.printf(
            "Debug task: %s, msg: %s\n",
            aResult.uid().c_str(),
            aResult.debug().c_str());
    }

    if (aResult.isError())
    {
        Firebase.printf(
            "Error task: %s, msg: %s, code: %d\n",
            aResult.uid().c_str(),
            aResult.error().message().c_str(),
            aResult.error().code());
    }

    if (aResult.available())
    {
        Firebase.printf(
            "Firestore payload: %s\n",
            aResult.c_str());
    }
}
