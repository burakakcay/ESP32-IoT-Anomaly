#pragma once

#include <Arduino.h>

struct VibrationSummary
{
    float lastRmsG = 0.0f;
    float peakG = 0.0f;

    uint32_t lastWindowAgeMs = 0;
    uint32_t intervalMs = 0;
    uint32_t validWindowCount = 0;

    bool hasValidLast = false;
    bool hasValidPeak = false;
    bool hadSaturation = false;
    bool hadSamplingError = false;
};

struct SensorReading
{
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
    bool hasValidMotion = false;
    VibrationSummary vibration;
};

void initializeSensors();
void updateVibrationSampling();
void collectVibrationForUpload(SensorReading &reading);

SensorReading readSensorData();

String createSensorJson(
    const SensorReading &reading,
    const char *deviceId);