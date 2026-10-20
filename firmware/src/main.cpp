#include "logger.h"
#include <Arduino.h>
#include <math.h>

#include "sensors.h"
#include "network_service.h"
#include "api_service.h"

const char deviceId[] = "ESP32_Sensor_Node_001";

// Son ölçüm hazırlama denemesinin zamanı.
unsigned long lastApiReading = 0;

// Grafik testleri için 5 saniyede bir ölçüm hazırla.
const unsigned long API_INTERVAL = 5000;

void logSlowOperation(
    const char *operation,
    uint32_t startedUs,
    uint32_t thresholdMs)
{
    const uint32_t elapsedUs = micros() - startedUs;

    if (elapsedUs / 1000.0 < thresholdMs)
        return;

    SentinelLog::write(
        SentinelLog::Level::Warning,
        "SURE",
        "%s: %.1f ms | Eşik: %lu ms",
        operation,
        elapsedUs / 1000.0,
        static_cast<unsigned long>(thresholdMs));
}

void setup()
{
    Serial.begin(115200);
    initializeSensors();
    initializeNetworkService(deviceId);
}

void loop()
{
    uint32_t startedUs = micros();
    updateNetworkService();
    logSlowOperation("Ağ işlemleri", startedUs, 100);

    updateApiService();

    startedUs = micros();
    updateVibrationSampling();
    logSlowOperation("Titreşim raporu işleme", startedUs, 50);

    if (
        isWifiConnected() &&
        canAcceptApiReading() &&
        millis() - lastApiReading >= API_INTERVAL)
    {
        lastApiReading = millis();

        startedUs = micros();
        SensorReading reading = readSensorData();
        logSlowOperation("Sensör okuma ve özet", startedUs, 50);

        if (!reading.hasValidMotion)
        {
            SentinelLog::write(
                SentinelLog::Level::Error,
                "SENSOR",
                "Güncel MPU6050 ölçümü yok; gönderim atlandı.");
            return;
        }

        if (!reading.hasValidTime)
        {
            SentinelLog::write(
                SentinelLog::Level::Error,
                "SAAT",
                "Zaman bilgisi yok; gönderim atlandı.");
            return;
        }

        collectVibrationForUpload(reading);

        startedUs = micros();
        const bool accepted = sendReadingToApi(reading, deviceId);
        logSlowOperation("API kayıt hazırlama", startedUs, 50);
        if (!accepted)
        {
            SentinelLog::write(
                SentinelLog::Level::Error,
                "API",
                "Ölçüm gönderim için kabul edilmedi.");
        }
    }
}
