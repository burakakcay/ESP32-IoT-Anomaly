#include "logger.h"
#include "sensors.h"

#include <Wire.h>
#include <DHT.h>
#include <MPU6050.h>
#include <time.h>
#include <math.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>

namespace
{
    constexpr uint8_t DHT_PIN = 5;
    constexpr float ACCEL_LSB_PER_G = 16384.0f;
    constexpr float GYRO_LSB_PER_DPS = 131.0f;

    constexpr int CALIBRATION_SAMPLES = 500;
    constexpr int CALIBRATION_ATTEMPTS = 3;

    constexpr float MAX_ACCEL_SPREAD_G = 0.08f;
    constexpr float MAX_GYRO_SPREAD_DPS = 1.5f;
    constexpr float MAX_GYRO_ABS_DPS = 10.0f;

    DHT dht(DHT_PIN, DHT22);
    MPU6050 mpu;

    float gyroOffset[3] = {};
    bool gyroCalibrated = false;

    struct MotionSnapshot
    {
        int16_t accel[3];
        int16_t gyro[3];
        uint32_t capturedMs;
        bool valid;
    };

    enum class VibrationStatus
    {
        Ready,
        ReadError,
        Gap,
        Saturation
    };

    struct VibrationReport
    {
        VibrationStatus status;
        float rms;
        float peak;
        float durationSeconds;
        float maxGapMs;
        uint32_t sequence;
    };

    QueueHandle_t motionQueue = nullptr;
    QueueHandle_t vibrationQueue = nullptr;
    TaskHandle_t vibrationTaskHandle = nullptr;
    portMUX_TYPE vibrationMux = portMUX_INITIALIZER_UNLOCKED;

    VibrationSummary pendingVibration{};
    uint32_t lastVibrationWindowMs = 0;
    uint32_t vibrationIntervalStartedMs = 0;
    bool vibrationCollectionStarted = false;

    void publishVibrationReport(const VibrationReport &report)
    {
        portENTER_CRITICAL(&vibrationMux);

        if (report.status == VibrationStatus::Ready)
        {
            pendingVibration.lastRmsG = report.rms;
            pendingVibration.hasValidLast = true;
            lastVibrationWindowMs = millis();

            if (!pendingVibration.hasValidPeak ||
                report.peak > pendingVibration.peakG)
            {
                pendingVibration.peakG = report.peak;
            }

            pendingVibration.hasValidPeak = true;
            ++pendingVibration.validWindowCount;
        }
        else if (report.status == VibrationStatus::Saturation)
        {
            pendingVibration.hadSaturation = true;
        }
        else
        {
            pendingVibration.hadSamplingError = true;
        }

        portEXIT_CRITICAL(&vibrationMux);

        xQueueOverwrite(vibrationQueue, &report);
    }

    void vibrationTask(void *)
    {
        constexpr int SAMPLE_COUNT = 200;
        constexpr uint32_t MAX_GAP_US = 30000;
        const TickType_t period = pdMS_TO_TICKS(10);

        static float samples[SAMPLE_COUNT][3];
        int count = 0;
        uint32_t lastUs = 0;
        uint32_t startUs = 0;
        uint32_t maxGapUs = 0;
        uint32_t sequence = 0;
        TickType_t wakeTime = xTaskGetTickCount();

        portENTER_CRITICAL(&vibrationMux);

        pendingVibration = VibrationSummary();
        vibrationIntervalStartedMs = millis();
        lastVibrationWindowMs = 0;
        vibrationCollectionStarted = true;

        portEXIT_CRITICAL(&vibrationMux);

        for (;;)
        {
            const uint32_t now = micros();
            const uint32_t gap = now - lastUs;
            lastUs = now;

            VibrationReport report{};

            if (count > 0 && gap > MAX_GAP_US)
            {
                count = 0;
                report.status = VibrationStatus::Gap;
                report.maxGapMs = gap / 1000.0f;
                publishVibrationReport(report);
            }

            uint8_t raw[14] = {};
            MotionSnapshot motion{};

            const int bytesRead = I2Cdev::readBytes(
                MPU6050_DEFAULT_ADDRESS,
                MPU6050_RA_ACCEL_XOUT_H,
                sizeof(raw),
                raw,
                10);

            if (bytesRead != sizeof(raw))
            {
                count = 0;
                motion.valid = false;
                xQueueOverwrite(motionQueue, &motion);

                report.status = VibrationStatus::ReadError;
                publishVibrationReport(report);
                vTaskDelay(pdMS_TO_TICKS(1000));
                wakeTime = xTaskGetTickCount();
                continue;
            }

            auto readInt16 = [&](int offset) -> int16_t
            {
                return static_cast<int16_t>(
                    (static_cast<uint16_t>(raw[offset]) << 8) |
                    raw[offset + 1]);
            };

            bool saturated = false;

            for (int axis = 0; axis < 3; axis++)
            {
                motion.accel[axis] = readInt16(axis * 2);
                motion.gyro[axis] = readInt16(8 + axis * 2);

                if (motion.accel[axis] >= 32700 ||
                    motion.accel[axis] <= -32700)
                    saturated = true;
            }
            motion.capturedMs = millis();
            motion.valid = true;
            xQueueOverwrite(motionQueue, &motion);

            if (saturated)
            {
                count = 0;
                report.status = VibrationStatus::Saturation;
                publishVibrationReport(report);
            }
            else
            {
                if (count == 0)
                {
                    startUs = now;
                    maxGapUs = 0;
                }
                else if (gap > maxGapUs)
                    maxGapUs = gap;

                for (int axis = 0; axis < 3; axis++)
                    samples[count][axis] = motion.accel[axis] / ACCEL_LSB_PER_G;

                ++count;

                if (count == SAMPLE_COUNT)
                {
                    double mean[3] = {};

                    for (int i = 0; i < SAMPLE_COUNT; i++)
                    {
                        for (int axis = 0; axis < 3; axis++)
                            mean[axis] += samples[i][axis];
                    }

                    for (int axis = 0; axis < 3; axis++)
                        mean[axis] /= SAMPLE_COUNT;

                    double sumSquares = 0.0;
                    double peakSquared = 0.0;

                    for (int i = 0; i < SAMPLE_COUNT; i++)
                    {
                        double magnitudeSquared = 0.0;

                        for (int axis = 0; axis < 3; axis++)
                        {
                            const double delta = samples[i][axis] - mean[axis];
                            magnitudeSquared += delta * delta;
                        }

                        sumSquares += magnitudeSquared;
                        if (magnitudeSquared > peakSquared)
                            peakSquared = magnitudeSquared;
                    }

                    report.status = VibrationStatus::Ready;
                    report.rms = sqrt(sumSquares / SAMPLE_COUNT);
                    report.peak = sqrt(peakSquared);
                    report.durationSeconds = (now - startUs) / 1000000.0f;
                    report.maxGapMs = maxGapUs / 1000.0f;
                    report.sequence = ++sequence;

                    publishVibrationReport(report);
                    count = 0;
                }
            }

            const TickType_t ticksNow = xTaskGetTickCount();
            if (ticksNow - wakeTime >= period)
                wakeTime = ticksNow;

            vTaskDelayUntil(&wakeTime, period);
        }
    }

    bool calibrateGyroscope()
    {
        gyroCalibrated = false;

        for (int attempt = 1; attempt <= CALIBRATION_ATTEMPTS; ++attempt)
        {
            SentinelLog::write(SentinelLog::Level::Info, "KALIBRASYON",
                               "%d/%d: Sensörü sabit tutun.",
                               attempt, CALIBRATION_ATTEMPTS);

            delay(2000);

            float minimum[6] = {};
            float maximum[6] = {};
            double gyroSum[3] = {};
            bool valid = true;

            for (int i = 0; i < CALIBRATION_SAMPLES; i++)
            {
                if (!mpu.testConnection())
                {
                    valid = false;
                    break;
                }

                int16_t ax = 0, ay = 0, az = 0;
                int16_t gx = 0, gy = 0, gz = 0;

                mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

                const float values[6] = {
                    ax / ACCEL_LSB_PER_G,
                    ay / ACCEL_LSB_PER_G,
                    az / ACCEL_LSB_PER_G,
                    gx / GYRO_LSB_PER_DPS,
                    gy / GYRO_LSB_PER_DPS,
                    gz / GYRO_LSB_PER_DPS,
                };

                const float magnitude = sqrtf(
                    values[0] * values[0] +
                    values[1] * values[1] +
                    values[2] * values[2]);

                if (magnitude < 0.8f || magnitude > 1.2f)
                    valid = false;

                for (int axis = 0; axis < 6; axis++)
                {
                    if (i == 0)
                    {
                        minimum[axis] = values[axis];
                        maximum[axis] = values[axis];
                    }
                    else
                    {
                        minimum[axis] = fminf(minimum[axis], values[axis]);
                        maximum[axis] = fmaxf(maximum[axis], values[axis]);
                    }
                }

                for (int axis = 0; axis < 3; axis++)
                {
                    gyroSum[axis] += values[axis + 3];

                    if (fabsf(values[axis + 3]) > MAX_GYRO_ABS_DPS)
                        valid = false;
                }
                delay(10);
            }

            for (int axis = 0; axis < 3; axis++)
            {
                if (maximum[axis] - minimum[axis] > MAX_ACCEL_SPREAD_G)
                    valid = false;

                if (maximum[axis + 3] - minimum[axis + 3] > MAX_GYRO_SPREAD_DPS)
                    valid = false;
            }

            if (!valid)
            {
                SentinelLog::write(SentinelLog::Level::Warning, "KALIBRASYON", "Hareket veya okuma sorunu; deneme reddedildi.");
                continue;
            }

            for (int axis = 0; axis < 3; axis++)
            {
                gyroOffset[axis] =
                    static_cast<float>(gyroSum[axis] / CALIBRATION_SAMPLES);
            }

            gyroCalibrated = true;

            SentinelLog::write(SentinelLog::Level::Info, "KALIBRASYON",
                               "Tamamlandı. Ofset [deg/s]: "
                               "X=%.3f Y=%.3f Z=%.3f",
                               gyroOffset[0], gyroOffset[1], gyroOffset[2]);

            return true;
        }
        SentinelLog::write(SentinelLog::Level::Error, "KALIBRASYON", "Basarisiz; ham jiroskop degerleri kullanilacak.");
        return false;
    }
}

void initializeSensors()
{
    Wire.begin(21, 22);

    mpu.initialize();
    mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_2);
    mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_250);

    dht.begin();
    delay(2000);

    if (mpu.testConnection())
    {
        calibrateGyroscope();
    }
    else
    {
        SentinelLog::write(SentinelLog::Level::Error, "SENSOR", "MPU6050 baglantisi kurulamadi.");
        return;
    }

    delay(2000);

    motionQueue = xQueueCreate(1, sizeof(MotionSnapshot));
    vibrationQueue = xQueueCreate(1, sizeof(VibrationReport));

    if (motionQueue == nullptr || vibrationQueue == nullptr)
    {
        if (motionQueue != nullptr)
            vQueueDelete(motionQueue);
        if (vibrationQueue != nullptr)
            vQueueDelete(vibrationQueue);

        motionQueue = nullptr;
        vibrationQueue = nullptr;

        SentinelLog::write(
            SentinelLog::Level::Error,
            "TITRESIM",
            "Kuyruklar olusturulamadi.");
        return;
    }

    // Mevcut çift çekirdekli ESP32 için.
    // Kalibrasyon tamamlandıktan sonra MPU6050'ye yalnızca bu görev erişir.
    const BaseType_t result = xTaskCreatePinnedToCore(
        vibrationTask,
        "vibration",
        4096,
        nullptr,
        2,
        &vibrationTaskHandle,
        1);

    if (result != pdPASS)
    {
        vQueueDelete(motionQueue);
        vQueueDelete(vibrationQueue);
        motionQueue = nullptr;
        vibrationQueue = nullptr;

        SentinelLog::write(
            SentinelLog::Level::Error,
            "TITRESIM",
            "Ornekleme gorevi baslatilamadi.");
    }
}

void updateVibrationSampling()
{
    if (vibrationQueue == nullptr)
        return;

    VibrationReport report{};

    if (xQueueReceive(vibrationQueue, &report, 0) != pdTRUE)
        return;

    if (report.status == VibrationStatus::Ready)
    {
        SentinelLog::write(
            SentinelLog::Level::Debug,
            "TITRESIM",
            "RMS:%.4fg | Tepe:%.4fg | "
            "Ornek:200 | Sure:%.2fs | MaksAralik:%.1fms",
            report.rms,
            report.peak,
            report.durationSeconds,
            report.maxGapMs);
        return;
    }

    // Tekrarlayan hata/uyarıların terminali doldurmasını önle.
    static bool warningPrinted = false;
    static uint32_t lastWarningMs = 0;
    const uint32_t now = millis();

    if (warningPrinted && now - lastWarningMs < 1000)
        return;

    warningPrinted = true;
    lastWarningMs = now;

    if (report.status == VibrationStatus::ReadError)
    {
        SentinelLog::write(
            SentinelLog::Level::Error,
            "TITRESIM",
            "MPU6050 okunamadi; pencere iptal edildi.");
    }
    else if (report.status == VibrationStatus::Gap)
    {
        SentinelLog::write(
            SentinelLog::Level::Warning,
            "TITRESIM",
            "Ornekleme kesintisi: %.1f ms; pencere yeniden baslatildi.",
            report.maxGapMs);
    }
    else
    {
        SentinelLog::write(
            SentinelLog::Level::Warning,
            "TITRESIM",
            "Ivme aralik sinirina ulasti; pencere iptal edildi.");
    }
}

void collectVibrationForUpload(SensorReading &reading)
{
    constexpr uint32_t MAX_LAST_WINDOW_AGE_MS = 3000;

    reading.vibration = VibrationSummary{};

    portENTER_CRITICAL(&vibrationMux);

    if (vibrationCollectionStarted)
    {
        const uint32_t now = millis();

        reading.vibration = pendingVibration;
        reading.vibration.intervalMs =
            now - vibrationIntervalStartedMs;

        if (reading.vibration.hasValidLast)
        {
            reading.vibration.lastWindowAgeMs =
                now - lastVibrationWindowMs;

            if (reading.vibration.lastWindowAgeMs >
                MAX_LAST_WINDOW_AGE_MS)
            {
                reading.vibration.hasValidLast = false;
            }
        }

        pendingVibration = VibrationSummary{};
        vibrationIntervalStartedMs = now;
    }

    portEXIT_CRITICAL(&vibrationMux);
}

SensorReading readSensorData()
{
    SensorReading reading{};

    reading.temperature = dht.readTemperature();
    reading.humidity = dht.readHumidity();

    MotionSnapshot motion{};

    if (motionQueue == nullptr ||
        xQueuePeek(motionQueue, &motion, 0) != pdTRUE ||
        !motion.valid ||
        millis() - motion.capturedMs > 100)
    {
        reading.hasValidMotion = false;
        return reading;
    }

    reading.hasValidMotion = true;

    reading.accelX = motion.accel[0];
    reading.accelY = motion.accel[1];
    reading.accelZ = motion.accel[2];

    reading.gyroX = motion.gyro[0];
    reading.gyroY = motion.gyro[1];
    reading.gyroZ = motion.gyro[2];

    const float ax = reading.accelX / ACCEL_LSB_PER_G;
    const float ay = reading.accelY / ACCEL_LSB_PER_G;
    const float az = reading.accelZ / ACCEL_LSB_PER_G;

    const float gx = reading.gyroX / GYRO_LSB_PER_DPS;
    const float gy = reading.gyroY / GYRO_LSB_PER_DPS;
    const float gz = reading.gyroZ / GYRO_LSB_PER_DPS;

    const float accelMagnitude = sqrtf(ax * ax + ay * ay + az * az);

    struct tm localTime;

    if (!getLocalTime(&localTime))
    {
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

    const String temperatureText = isnan(reading.temperature)
                                       ? String("--")
                                       : String(reading.temperature, 1);

    const String humidityText = isnan(reading.humidity)
                                    ? String("--")
                                    : String(reading.humidity, 1);

    SentinelLog::write(SentinelLog::Level::Debug, "OLCUM",
                       "%s | T:%sC H:%s%% | "
                       "A[g]:%.3f,%.3f,%.3f | |A|:%.3fg | "
                       "G[deg/s]:%.2f,%.2f,%.2f (%s)",
                       reading.timestamp.c_str(),
                       temperatureText.c_str(),
                       humidityText.c_str(),
                       ax, ay, az,
                       accelMagnitude,
                       gyroCalibrated ? gx - gyroOffset[0] : gx,
                       gyroCalibrated ? gy - gyroOffset[1] : gy,
                       gyroCalibrated ? gz - gyroOffset[2] : gz,
                       gyroCalibrated ? "Düzeltilmiş." : "Kalibrasyon yok.");

    return reading;
}

String createSensorJson(
    const SensorReading &reading,
    const char *deviceId)
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
