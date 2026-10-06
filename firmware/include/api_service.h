#pragma once

#include "sensors.h"

bool canAcceptApiReading();

bool sendReadingToApi(
    const SensorReading &reading,
    const char *deviceId);

void updateApiService();