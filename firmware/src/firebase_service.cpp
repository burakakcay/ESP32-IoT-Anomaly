#include "logger.h"

#define ENABLE_USER_AUTH
#define ENABLE_FIRESTORE

#include <Arduino.h>
#include <FirebaseClient.h>
#include <math.h>
#include <esp_system.h>

#include "ExampleFunctions.h"
#include "secrets.h"
#include "firebase_service.h"

static void uploadReadingDocument(
    const SensorReading &reading,
    const char *deviceId,
    const String &documentId,
    const String &taskUid);

namespace
{
    SSL_CLIENT ssl_client;

    using AsyncClient = AsyncClientClass;
    AsyncClient asyncClient(ssl_client);

    void processFirestoreResult(AsyncResult &aResult);

    FirebaseApp app;
    Firestore::Documents documents;

    UserAuth user_auth(
        FIREBASE_API_KEY,
        FIREBASE_USER_EMAIL,
        FIREBASE_USER_PASSWORD,
        3000);

    bool firebaseServiceInitialized = false;
    bool firebaseAuthenticationLogged = false;

    constexpr uint32_t INITIAL_RETRY_DELAY_MS = 5000;
    constexpr uint32_t MAX_RETRY_DELAY_MS = 60000;
    constexpr uint32_t UPLOAD_TIMEOUT_MS = 60000;

    struct PendingReading
    {
        SensorReading reading{};
        String deviceId;
        String documentId;
        String taskUid;

        bool occupied = false;
        bool inFlight = false;
        bool retryScheduled = false;

        uint32_t lastFailureMs = 0;
        uint32_t attemptStartedMs = 0;
        uint32_t retryDelayMs = INITIAL_RETRY_DELAY_MS;
        uint32_t attempt = 0;
    };

    PendingReading pendingReading;

    void startPendingUpload()
    {
        if (!pendingReading.occupied || pendingReading.inFlight || !app.ready())
        {
            return;
        }

        ++pendingReading.attempt;
        pendingReading.taskUid = pendingReading.documentId + "-" + String(pendingReading.attempt);

        pendingReading.inFlight = true;
        pendingReading.retryScheduled = false;

        pendingReading.attemptStartedMs = millis();

        SentinelLog::write(
            SentinelLog::Level::Debug,
            "FIRESTORE",
            "Göndeirm denemesi: %lu",
            static_cast<unsigned long>(pendingReading.attempt));

        uploadReadingDocument(
            pendingReading.reading,
            pendingReading.deviceId.c_str(),
            pendingReading.documentId,
            pendingReading.taskUid);
    }

    void processFirestoreResult(AsyncResult &aResult)
    {
        if (!aResult.isResult())
            return;

        if (!pendingReading.occupied ||
            !pendingReading.inFlight ||
            aResult.uid() != pendingReading.taskUid)
        {
            if (aResult.available())
                (void)aResult.c_str();

            return;
        }

        if (aResult.isError())
        {
            const int code = aResult.error().code();

            // Aynı kimlikle önceki denemede oluşturulmuş olabilir.
            if (code == 409)
            {
                if (aResult.available())
                    (void)aResult.c_str();

                pendingReading = PendingReading{};

                SentinelLog::write(
                    SentinelLog::Level::Debug,
                    "FIRESTORE", "Kayıt zaten mevcut; gönderim tamamlandı.");

                return;
            }

            // ilk hata 5 sn; sonraki hatalar 10, 20, 40, 60 sn
            if (pendingReading.attempt > 1)
            {
                const uint32_t doubled = pendingReading.retryDelayMs * 2;

                pendingReading.retryDelayMs =
                    doubled > MAX_RETRY_DELAY_MS
                        ? MAX_RETRY_DELAY_MS
                        : doubled;
            }

            pendingReading.inFlight = false;
            pendingReading.retryScheduled = true;
            pendingReading.lastFailureMs = millis();

            SentinelLog::write(
                SentinelLog::Level::Warning,
                "FIRESTORE",
                "Kod %d: %s | Kayıt korundu; %lu sn sonra tekrar.",
                code,
                aResult.error().message().c_str(),
                static_cast<unsigned long>(pendingReading.retryDelayMs / 1000));

            if (aResult.available())
                (void)aResult.c_str();

            return;
        }

        if (aResult.available())
        {
            (void)aResult.c_str();
            pendingReading = PendingReading{};

            SentinelLog::write(
                SentinelLog::Level::Debug,
                "FIRESTORE",
                "Kaydedildi.");
        }
    }

    void processAuthResult(AsyncResult &aResult)
    {
        if (!aResult.isResult())
            return;
        if (aResult.isError())
        {
            SentinelLog::write(SentinelLog::Level::Error, "FIREBASE",
                               "Kod %d: %s",
                               aResult.error().code(),
                               aResult.error().message().c_str());
        }
    }
}

void initializeFirebaseService()
{
    if (firebaseServiceInitialized)
    {
        return;
    }

    set_ssl_client_insecure_and_buffer(ssl_client);

    initializeApp(
        asyncClient,
        app,
        getAuth(user_auth),
        processAuthResult,
        "firebaseAuthTask");
    app.getApp<Firestore::Documents>(documents);

    firebaseServiceInitialized = true;
}

void updateFirebaseService()
{
    if (!firebaseServiceInitialized)
    {
        return;
    }

    app.loop();

    if (pendingReading.occupied &&
        pendingReading.inFlight &&
        millis() - pendingReading.attemptStartedMs >= UPLOAD_TIMEOUT_MS)
    {
        // Önce durum değişsin; iptal edilen isteğin geç gelen
        // callback'i mevcut kaydı tamamlanmış saymasın.
        pendingReading.inFlight = false;
        pendingReading.retryScheduled = true;
        pendingReading.lastFailureMs = millis();

        if (pendingReading.attempt > 1)
        {
            const uint32_t doubled = pendingReading.retryDelayMs * 2;

            pendingReading.retryDelayMs = doubled > MAX_RETRY_DELAY_MS
                                              ? MAX_RETRY_DELAY_MS
                                              : doubled;
        }

        // Yalnızca bu gönderim denemesini iptal et.
        asyncClient.stopAsync(pendingReading.taskUid);

        SentinelLog::write(
            SentinelLog::Level::Warning,
            "FIRESTORE",
            "Gonderim zaman asimina ugradi; kayit korundu. "
            "%lu sn sonra Firebase hazirsa tekrar denenecek.",
            static_cast<unsigned long>(
                pendingReading.retryDelayMs / 1000));
    }

    if (app.ready() && !firebaseAuthenticationLogged)
    {
        firebaseAuthenticationLogged = true;

        SentinelLog::write(SentinelLog::Level::Info, "FIREBASE", "Oturum açıldı.");
    }

    if (app.ready() &&
        pendingReading.occupied &&
        !pendingReading.inFlight &&
        pendingReading.retryScheduled &&
        millis() - pendingReading.lastFailureMs >=
            pendingReading.retryDelayMs)
    {
        // Önceki isteğin kütüphanede kalan görevini iptal et.
        // Kimlik yalnızca o gönderim denemesine ait.

        asyncClient.stopAsync(pendingReading.taskUid);
        startPendingUpload();
    }
}

bool isFirebaseReady()
{
    return firebaseServiceInitialized && app.ready();
}

void uploadReadingDocument(
    const SensorReading &reading,
    const char *deviceId,
    const String &documentId,
    const String &taskUid)
{

    if (!reading.hasValidTime)
    {
        SentinelLog::write(SentinelLog::Level::Error, "FIRESTORE", "Zaman bilgisi yok; gonderim atlandi.");
        return;
    }

    const String documentPath =
        "devices/" +
        String(deviceId) +
        "/readings";

    Values::StringValue deviceIdValue(deviceId);
    Values::StringValue timestampValue(reading.timestamp);
    Values::DoubleValue temperatureValue(number_t(reading.temperature, 2));
    Values::DoubleValue humidityValue(number_t(reading.humidity, 2));

    Values::IntegerValue accelXValue(reading.accelX);
    Values::IntegerValue accelYValue(reading.accelY);
    Values::IntegerValue accelZValue(reading.accelZ);

    Values::IntegerValue gyroXValue(reading.gyroX);
    Values::IntegerValue gyroYValue(reading.gyroY);
    Values::IntegerValue gyroZValue(reading.gyroZ);

    Document<Values::Value> doc(
        "device_id", Values::Value(deviceIdValue));
    doc.add("timestamp", Values::Value(timestampValue));
    if (!isnan(reading.temperature))
    {
        doc.add("temperature", Values::Value(temperatureValue));
    }
    else
    {
        doc.add("temperature", Values::Value(Values::NullValue()));
        SentinelLog::write(SentinelLog::Level::Warning, "SENSOR", "Sicaklik gecersiz; null kaydedilecek.");
    }
    if (!isnan(reading.humidity))
    {
        doc.add(
            "humidity",
            Values::Value(humidityValue));
    }
    else
    {
        doc.add(
            "humidity",
            Values::Value(Values::NullValue()));
    }

    doc.add("accel_x", Values::Value(accelXValue));
    doc.add("accel_y", Values::Value(accelYValue));
    doc.add("accel_z", Values::Value(accelZValue));

    doc.add("gyro_x", Values::Value(gyroXValue));
    doc.add("gyro_y", Values::Value(gyroYValue));
    doc.add("gyro_z", Values::Value(gyroZValue));

    const VibrationSummary &vibration = reading.vibration;

    if (vibration.hasValidLast && isfinite(vibration.lastRmsG))
    {
        doc.add(
            "last_rms_g",
            Values::Value(
                Values::DoubleValue(number_t(vibration.lastRmsG, 4))));
    }
    else
    {
        doc.add("last_rms_g", Values::Value(Values::NullValue()));
    }

    if (vibration.hasValidPeak && isfinite(vibration.peakG))
    {
        doc.add(
            "peak_g",
            Values::Value(
                Values::DoubleValue(number_t(vibration.peakG, 4))));
    }
    else
    {
        doc.add("peak_g", Values::Value(Values::NullValue()));
    }

    if (vibration.validWindowCount > 0)
    {
        doc.add(
            "vibration_last_age_ms",
            Values::Value(
                Values::IntegerValue(vibration.lastWindowAgeMs)));
    }
    else
    {
        doc.add(
            "vibration_last_age_ms",
            Values::Value(Values::NullValue()));
    }

    doc.add(
        "vibration_interval_ms",
        Values::Value(
            Values::IntegerValue(vibration.intervalMs)));

    doc.add(
        "vibration_window_count",
        Values::Value(Values::IntegerValue(vibration.validWindowCount)));

    doc.add(
        "vibration_saturated",
        Values::Value(Values::BooleanValue(vibration.hadSaturation)));

    doc.add(
        "vibration_sampling_error",
        Values::Value(Values::BooleanValue(vibration.hadSamplingError)));

    documents.createDocument(
        asyncClient,
        Firestore::Parent(FIREBASE_PROJECT_ID),
        documentPath,
        documentId,
        DocumentMask(),
        doc,
        processFirestoreResult,
        taskUid);
}

bool canAcceptFirestoreReading()
{
    return isFirebaseReady() && !pendingReading.occupied;
}

void sendReadingToFirestore(
    const SensorReading &reading,
    const char *deviceId)
{
    if (pendingReading.occupied)
    {
        SentinelLog::write(
            SentinelLog::Level::Warning,
            "FIRESTORE",
            "Önceki kayıt bekleniyor; yeni kayıt kabul edilmedi.");

        return;
    }

    if (!reading.hasValidTime || !reading.hasValidMotion)
    {
        SentinelLog::write(
            SentinelLog::Level::Error,
            "FIRESTORE",
            "Ölçüm veya zaman geçersiz; kayıt kabul edilmedi.");

        return;
    }

    char id[48];
    snprintf(
        id,
        sizeof(id),
        "%08lx-%08lx-%08lx-%08lx",
        static_cast<unsigned long>(esp_random()),
        static_cast<unsigned long>(esp_random()),
        static_cast<unsigned long>(esp_random()),
        static_cast<unsigned long>(esp_random()));

    pendingReading = PendingReading{};
    pendingReading.reading = reading;
    pendingReading.deviceId = deviceId;
    pendingReading.documentId = id;
    pendingReading.occupied = true;

    startPendingUpload();
}