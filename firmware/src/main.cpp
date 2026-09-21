#include <Arduino.h>

#include "sensors.h"
#include "network_service.h"
#include "firebase_service.h"

const char deviceId[] = "ESP32_Sensor_Node_001";

// Firestore gönderimi ile Wi-Fi yeniden bağlanma zamanlarını tutar.
unsigned long lastFirestoreSend = 0;

// Firestore kotasını korumak için sensör verilerini 15 saniyede bir gönderir.
const unsigned long FIRESTORE_INTERVAL = 15000;

// ESP32 yaşam döngüsü

void setup()
{
    Serial.begin(115200);
    initializeSensors();
    initializeNetworkService(deviceId);
    initializeFirebaseService();
}

void loop()
{
    updateNetworkService();
    updateFirebaseService();

    if (
        isWifiConnected() &&
        isFirebaseReady() &&
        millis() - lastFirestoreSend >= FIRESTORE_INTERVAL)
    {
        lastFirestoreSend = millis();

        const SensorReading reading = readSensorData();

        if (!reading.hasValidTime)
        {
            Serial.println("{\"status\":\"time_not_set\"}");
            return;
        }

        Serial.println(createSensorJson(reading, deviceId));

        sendReadingToFirestore(reading, deviceId);
    }
}
// Firestore
