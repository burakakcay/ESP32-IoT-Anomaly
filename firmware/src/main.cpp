#include "logger.h"
#include <Arduino.h>
#include <math.h>

#include "sensors.h"
#include "network_service.h"
#include "api_service.h"

const char deviceId[] = "ESP32_Sensor_Node_001";

// Son ölçüm hazırlama denemesinin zamanı.
unsigned long lastApiReading = 0;

// İlk bağlantı denemelerinde 15 saniyelik aralık kullanıyoruz.
const unsigned long API_INTERVAL = 15000;

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
}

void loop()
{
    uint32_t startedUs = micros();
    updateNetworkService();
    logSlowOperation("Ag islemleri", startedUs);

    startedUs = micros();
    updateApiService();
    logSlowOperation("API gönderim islemleri", startedUs);

    startedUs = micros();
    updateVibrationSampling();
    logSlowOperation("Titreşim işlemleri", startedUs);

    if (
        isWifiConnected() &&
        canAcceptApiReading() &&
        millis() - lastApiReading >= API_INTERVAL)
    {
        lastApiReading = millis();

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
        const bool accepted = sendReadingToApi(reading, deviceId);
        logSlowOperation("API kayıt hazırlama", startedUs);
        if (!accepted)
        {
            SentinelLog::write(
                SentinelLog::Level::Error,
                "API",
                "Ölçüm gönderim için kabul edilmedi.");
        }
    }
}