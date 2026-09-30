#include "logger.h"
#include "network_service.h"

#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <time.h>

#include "secrets.h"
#include "sensors.h"

namespace
{
    WebServer server(80);

    const char *activeDeviceId = nullptr;

    bool networkServiceStarted = false;

    unsigned long lastWifiReconnectAttempt = 0;
    unsigned long lastTimeSyncAttempt = 0;

    constexpr uint32_t WIFI_TIMEOUT_MS = 15000;
    constexpr uint32_t WIFI_RETRY_INTERVAL_MS = 30000;
    constexpr uint32_t NTP_TIMEOUT_MS = 10000;
    constexpr uint32_t RESYNC_INTERVAL_MS =
        24UL * 60UL * 60UL * 1000UL;

    bool connectWifi()
    {
        WiFi.mode(WIFI_STA);
        WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

        const uint32_t startAttemptTime = millis();

        while (
            WiFi.status() != WL_CONNECTED &&
            millis() - startAttemptTime < WIFI_TIMEOUT_MS)
        {
            delay(500);
        }

        return WiFi.status() == WL_CONNECTED;
    }

    bool syncTimeFromNTP()
    {
        configTime(0, 0, NTP_SERVER);
        setenv("TZ", TZ_INFO, 1);
        tzset();

        const uint32_t startAttemptTime = millis();
        struct tm timeInfo;

        while (millis() - startAttemptTime < NTP_TIMEOUT_MS)
        {
            if (getLocalTime(&timeInfo))
            {
                return true;
            }

            delay(500);
        }

        return false;
    }

    void handleSensor()
    {
        const SensorReading reading = readSensorData();

        if (!reading.hasValidMotion)
        {
            server.send(
                503,
                "application/json",
                "{\"status\":\"motion_unavailable\"}");
            return;
        }

        if (!reading.hasValidTime)
        {
            server.send(
                503,
                "application/json",
                "{\"status\":\"time_not_set\"}");
            return;
        }

        server.send(
            200,
            "application/json",
            createSensorJson(reading, activeDeviceId));
    }

    void startHttpServer()
    {
        if (networkServiceStarted)
        {
            return;
        }

        server.on("/sensor", HTTP_GET, handleSensor);
        server.begin();

        networkServiceStarted = true;
    }

    void reconnectWifiIfNeeded()
    {
        if (isWifiConnected())
        {
            return;
        }

        if (millis() - lastWifiReconnectAttempt < WIFI_RETRY_INTERVAL_MS)
        {
            return;
        }

        lastWifiReconnectAttempt = millis();

        SentinelLog::write(SentinelLog::Level::Warning, "WIFI", "Yeniden baglaniliyor...");

        if (connectWifi())
        {
            SentinelLog::write(SentinelLog::Level::Info, "WIFI", "Bağlandı. IP: %s", WiFi.localIP().toString().c_str());

            if (!networkServiceStarted)
            {
                startHttpServer();
            }

            if (!syncTimeFromNTP())
            {
                SentinelLog::write(SentinelLog::Level::Error, "SAAT", "Senkronizasyon basarisiz.");
            }
        }
        else
        {
            SentinelLog::write(SentinelLog::Level::Error, "WIFI", "Yeniden baglanti kurulamadi.");
        }
    }

    void resyncTimeIfNeeded()
    {
        if (millis() - lastTimeSyncAttempt < RESYNC_INTERVAL_MS)
        {
            return;
        }

        lastTimeSyncAttempt = millis();

        if (!isWifiConnected())
        {
            return;
        }

        if (!syncTimeFromNTP())
        {
            SentinelLog::write(SentinelLog::Level::Error, "SAAT", "Senkronizasyon basarisiz.");
        }
    }
}

void initializeNetworkService(const char *deviceId)
{
    activeDeviceId = deviceId;

    if (!connectWifi())
    {
        SentinelLog::write(SentinelLog::Level::Error, "WIFI", "Bağlantı kurulamadı.");
        return;
    }

    SentinelLog::write(SentinelLog::Level::Info, "WIFI", "Bağlandı. IP: %s", WiFi.localIP().toString().c_str());

    if (!syncTimeFromNTP())
    {
        SentinelLog::write(SentinelLog::Level::Error, "SAAT", "Senkronizasyon başarısız.");
    }

    startHttpServer();
}

void updateNetworkService()
{
    reconnectWifiIfNeeded();

    if (networkServiceStarted && isWifiConnected())
    {
        server.handleClient();
    }

    resyncTimeIfNeeded();
}

bool isWifiConnected()
{
    return WiFi.status() == WL_CONNECTED;
}
