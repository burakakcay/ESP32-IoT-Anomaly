#pragma once

#include <Arduino.h>

struct SensorReading {
    float temperature;
    float humidity;

    int16_t accelX;
    int16_t accelY;
    int16_t accelZ;

    int16_t gyroX;
    int16_t gyroY;
    int16_t gyroZ;

    String timestamp;
    bool hasValidTime;
};

void initializeSensors();

SensorReading readSensorData();

String createSensorJson(
    const SensorReading& reading,
    const char* deviceId);