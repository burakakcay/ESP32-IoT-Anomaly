#pragma once

#include "sensors.h"

void initializeFirebaseService();

void updateFirebaseService();

bool isFirebaseReady();

void sendReadingToFirestore(
    const SensorReading &reading,
    const char *deviceId);