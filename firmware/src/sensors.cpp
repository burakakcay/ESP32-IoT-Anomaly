#include "sensors.h"

#include <Wire.h>
#include <DHT.h>
#include <MPU6050.h>
#include <time.h>
#include <math.h>

namespace {
    constexpr uint8_t DHT_PIN = 5;

    DHT dht(DHT_PIN, DHT22);
    MPU6050 mpu;
}

void initializeSensors()
{
    Wire.begin(21, 22);

    mpu.initialize();
    dht.begin();

    if (mpu.testConnection()) {
        Serial.println("{\"status\":\"boot_ok\"}");
    } else {
        Serial.println("{\"status\":\"mpu_couldn't_initialize\"}");
    }

    delay(2000);
}

SensorReading readSensorData()
{
    SensorReading reading;

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

    if (!getLocalTime(&localTime)) {
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

String createSensorJson(
    const SensorReading& reading,
    const char* deviceId)
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