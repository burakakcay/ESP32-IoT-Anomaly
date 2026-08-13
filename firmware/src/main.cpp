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

// Fonksiyon prototipleri
bool connectWifi();
void disconnectWifi();
void createSensorDocument();
void processFirestoreResult(AsyncResult &aResult);
String createSensorJson();
void handleSensor();
bool syncTimeFromNTP();
void resyncTimeIfNeeded();

DHT dht(5, DHT22); // DHT22 sensörünün bağlı olduğu GPIO pini
MPU6050 mpu;
WebServer server(80);

FirebaseApp app;
Firestore::Documents Docs;
AsyncResult firestoreResult;

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

bool firebaseReady = false;
bool firestoreTestDone = false;

unsigned long lastFirestoreSend = 0;
const unsigned long FIRESTORE_INTERVAL = 5000;

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

        set_ssl_client_insecure_and_buffer(ssl_client);

        Serial.println("Firebase başlatılıyor...");

        initializeApp(
            aClient,
            app,
            getAuth(user_auth),
            auth_debug_print,
            "firebaseAuthTask");

        app.getApp<Firestore::Documents>(Docs);

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

    app.loop();

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

    if (app.ready() && millis() - lastFirestoreSend >= FIRESTORE_INTERVAL)
    {
        lastFirestoreSend = millis();

        Serial.println(createSensorJson());

        createSensorDocument();
    }
}

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

void createSensorDocument()
{
    float sicaklik = dht.readTemperature();
    float nem = dht.readHumidity();

    int16_t ax, ay, az;
    int16_t gx, gy, gz;

    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    struct tm localTime;

    if (!getLocalTime(&localTime))
    {
        Serial.println("Firestore: Zaman bilgisi alınamadı.");
        return;
    }

    char isoTime[32];

    strftime(
        isoTime,
        sizeof(isoTime),
        "%Y-%m-%dT%H:%M:%S",
        &localTime);

    String documentPath =
        "devices/" +
        String(deviceId) +
        "/readings";

    Values::StringValue deviceIdV(deviceId);
    Values::StringValue timestampV(isoTime);

    Values::DoubleValue temperatureV(
        number_t(sicaklik, 2));

    Values::DoubleValue humidityV(
        number_t(nem, 2));

    Values::IntegerValue accelXV(ax);
    Values::IntegerValue accelYV(ay);
    Values::IntegerValue accelZV(az);

    Values::IntegerValue gyroXV(gx);
    Values::IntegerValue gyroYV(gy);
    Values::IntegerValue gyroZV(gz);

    Document<Values::Value> doc(
        "device_id",
        Values::Value(deviceIdV));

    doc.add(
        "timestamp",
        Values::Value(timestampV));

    if (!isnan(sicaklik))
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

    if (!isnan(nem))
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
