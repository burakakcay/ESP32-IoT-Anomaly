#include "logger.h"

#define ENABLE_USER_AUTH
#define ENABLE_FIRESTORE

#include <Arduino.h>
#include <FirebaseClient.h>
#include <math.h>

#include "ExampleFunctions.h"
#include "secrets.h"
#include "firebase_service.h"

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

    void processFirestoreResult(AsyncResult &aResult)
    {
        if (!aResult.isResult())
            return;

        if (aResult.isError())
        {
            SentinelLog::write(SentinelLog::Level::Error, "FIRESTORE",
                               "Kod %d: %s",
                               aResult.error().code(),
                               aResult.error().message().c_str());
            return;
        }

        if (aResult.available())
        {
            (void)aResult.c_str();
            SentinelLog::write(SentinelLog::Level::Debug, "FIRESTORE", "Kaydedildi.");
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

    if (app.ready() && !firebaseAuthenticationLogged)
    {
        firebaseAuthenticationLogged = true;

        SentinelLog::write(SentinelLog::Level::Info, "FIREBASE", "Oturum açıldı.");
    }
}

bool isFirebaseReady()
{
    return firebaseServiceInitialized && app.ready();
}

void sendReadingToFirestore(
    const SensorReading &reading,
    const char *deviceId)
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

    documents.createDocument(
        asyncClient,
        Firestore::Parent(FIREBASE_PROJECT_ID),
        documentPath,
        DocumentMask(),
        doc,
        processFirestoreResult,
        "sensorDataTask");
}
