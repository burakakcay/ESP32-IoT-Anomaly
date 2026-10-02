#include "logger.h"
#include <Arduino.h>
#include <math.h>

#include "sensors.h"
#include "network_service.h"
#include "firebase_service.h"

const char deviceId[] = "ESP32_Sensor_Node_001";

// Firestore gönderimi ile Wi-Fi yeniden bağlanma zamanlarını tutar.
unsigned long lastFirestoreSend = 0;

// Firestore kotasını korumak için sensör verilerini 15 saniyede bir gönderir.
const unsigned long FIRESTORE_INTERVAL = 15000;

void logSlowOperation(const char *operation, uint32_t startedUs)
{
    const uint32_t elapsedUs = micros() - startedUs;

    if (elapsedUs < 10000)
        return;

    SentinelLog::write(
        SentinelLog::Level::Warning,
        "SURE",
        "%s: %.1f ms",
        operation,
        elapsedUs / 1000.0);
}

void setup()
{
    Serial.begin(115200);
    initializeSensors();
    initializeNetworkService(deviceId);
    initializeFirebaseService();
}

void loop()
{
    uint32_t startedUs = micros();
    updateNetworkService();
    logSlowOperation("Ag islemleri", startedUs);

    startedUs = micros();
    updateFirebaseService();
    logSlowOperation("Firebase islemleri", startedUs);

    startedUs = micros();
    updateVibrationSampling();
    logSlowOperation("Titresim islemleri", startedUs);

    if (
        isWifiConnected() &&
        canAcceptFirestoreReading() &&
        millis() - lastFirestoreSend >= FIRESTORE_INTERVAL)
    {
        lastFirestoreSend = millis();

        startedUs = micros();
        SensorReading reading = readSensorData();
        logSlowOperation("Sensor okuma ve ozet", startedUs);

        if (!reading.hasValidMotion)
        {
            SentinelLog::write(
                SentinelLog::Level::Error,
                "SENSOR",
                "Guncel MPU6050 olcumu yok; gonderim atlandi.");
            return;
        }

        if (!reading.hasValidTime)
        {
            SentinelLog::write(
                SentinelLog::Level::Error,
                "SAAT",
                "Zaman bilgisi yok; gonderim atlandi.");
            return;
        }

        collectVibrationForUpload(reading);

        startedUs = micros();
        sendReadingToFirestore(reading, deviceId);
        logSlowOperation("Firestore gonderim cagrisi", startedUs);
    }
}