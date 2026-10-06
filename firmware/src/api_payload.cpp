#include "api_payload.h"
#include <math.h>

namespace
{
    String numberOrNull(float value, unsigned int decimals)
    {
        return isfinite(value)
                   ? String(value, decimals)
                   : String("null");
    }

    bool validIdentifier(const String &value)
    {
        if (value.length() == 0 || value.length() > 64)
            return false;

        for (unsigned int i = 0; i < value.length(); i++)
        {
            const char c = value[i];

            if (!((c >= 'a' && c <= 'z') ||
                  (c >= 'A' && c <= 'Z') ||
                  (c >= '0' && c <= '9') ||
                  c == '_' || c == '-'))
            {
                return false;
            }
        }
        return true;
    }
}

String createApiReadingJson(
    const SensorReading &reading,
    const char *deviceId,
    const String &readingId)
{
    if (deviceId == nullptr ||
        !validIdentifier(String(deviceId)) ||
        !validIdentifier(readingId) ||
        !reading.hasValidTime ||
        !reading.hasValidMotion)
    {
        return String();
    }

    const VibrationSummary &vibration = reading.vibration;

    String json;
    json.reserve(768);

    json += "{\"device_id\":\"";
    json += deviceId;
    json += "\",\"reading_id\":\"";
    json += readingId;
    json += "\",\"timestamp\":\"";
    json += reading.timestamp;
    json += "\"";

    json += ",\"temperature\":";
    json += numberOrNull(reading.temperature, 2);

    json += ",\"humidity\":";
    json += numberOrNull(reading.humidity, 2);

    json += ",\"accel_x\":" + String(reading.accelX);
    json += ",\"accel_y\":" + String(reading.accelY);
    json += ",\"accel_z\":" + String(reading.accelZ);

    json += ",\"gyro_x\":" + String(reading.gyroX);
    json += ",\"gyro_y\":" + String(reading.gyroY);
    json += ",\"gyro_z\":" + String(reading.gyroZ);

    json += ",\"last_rms_g\":";
    json += vibration.hasValidLast
                ? numberOrNull(vibration.lastRmsG, 4)
                : String("null");

    json += ",\"peak_g\":";
    json += vibration.hasValidPeak
                ? numberOrNull(vibration.peakG, 4)
                : String("null");

    json += ",\"vibration_interval_ms\":";
    json += String(vibration.intervalMs);

    json += ",\"vibration_last_age_ms\":";
    json += vibration.validWindowCount > 0
                ? String(vibration.lastWindowAgeMs)
                : String("null");

    json += ",\"vibration_window_count\":";
    json += String(vibration.validWindowCount);

    json += ",\"vibration_sampling_error\":";
    json += vibration.hadSamplingError ? "true" : "false";

    json += ",\"vibration_saturated\":";
    json += vibration.hadSaturation ? "true" : "false";

    json += "}";

    return json;
}