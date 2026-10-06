#pragma once

#include <Arduino.h>
#include "sensors.h"

String createApiReadingJson(
    const SensorReading &reading,
    const char *deviceId,
    const String &readingId);