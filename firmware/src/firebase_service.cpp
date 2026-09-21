
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
        // FirebaseClient asenkron sonucu yoksa işlenecek durum da yoktur.
        if (!aResult.isResult())
            return;

        if (aResult.isEvent())
        {
            Firebase.printf(
                "Event task: %s, msg: %s, code: %d\n",
                aResult.uid().c_str(),
                aResult.eventLog().message().c_str(),
                aResult.eventLog().code());
        }

        if (aResult.isDebug())
        {
            Firebase.printf(
                "Debug task: %s, msg: %s\n",
                aResult.uid().c_str(),
                aResult.debug().c_str());
        }

        if (aResult.isError())
        {
            Firebase.printf(
                "Error task: %s, msg: %s, code: %d\n",
                aResult.uid().c_str(),
                aResult.error().message().c_str(),
                aResult.error().code());
        }

        if (aResult.available())
        {
            Firebase.printf(
                "Firestore payload: %s\n",
                aResult.c_str());
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

    Serial.println("Firebase servisi başlatılıyor...");

    initializeApp(
        asyncClient,
        app,
        getAuth(user_auth),
        auth_debug_print,
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

        Serial.println("================================");
        Serial.println("Firebase authentication başarılı!");
        Serial.print("UID: ");
        Serial.println(app.getUid());
        Serial.println("================================");
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
        Serial.println("Firestore: Zaman bilgisi alınamadı.");
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
        "device_Id", Values::Value(deviceIdValue));
    doc.add("timestamp", Values::Value(timestampValue));
    if (!isnan(reading.temperature))
    {
        doc.add("temperature", Values::Value(temperatureValue));
    }
    else
    {
        doc.add("temperature", Values::Value(Values::NullValue()));
        Serial.println("Firestore: Sıcaklık verisi geçersiz, gönderilmiyor.");
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

    Serial.println("Firestore: Sensör verisi gönderiliyor...");
    documents.createDocument(
        asyncClient,
        Firestore::Parent(FIREBASE_PROJECT_ID),
        documentPath,
        DocumentMask(),
        doc,
        processFirestoreResult,
        "sensorDataTask");
}