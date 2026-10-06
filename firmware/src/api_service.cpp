#include "api_service.h"
#include "api_payload.h"
#include "logger.h"
#include "secrets.h"

#include <WiFi.h>
#include <HTTPClient.h>
#include <esp_system.h>

namespace
{
    constexpr uint32_t INITIAL_RETRY_MS = 5000;
    constexpr uint32_t MAX_RETRY_MS = 60000;

    struct PendingUpload
    {
        String payload;

        bool occupied = false;
        bool blocked = false;

        uint32_t attempt = 0;
        uint32_t lastFailureMs = 0;
        uint32_t retryDelayMs = INITIAL_RETRY_MS;
    };
    PendingUpload pending;
}

bool canAcceptApiReading()
{
    return !pending.occupied;
}

bool sendReadingToApi(
    const SensorReading &reading,
    const char *deviceId)
{
    if (pending.occupied)
        return false;

    if (!String(SENTINEL_API_URL).startsWith("http://"))
    {
        SentinelLog::write(
            SentinelLog::Level::Error,
            "API",
            "Yerel API adresi http:// ile başlamalı.");

        return false;
    }

    char readingId[48];

    snprintf(
        readingId,
        sizeof(readingId),
        "%08lx-%08lx-%08lx-%08lx",
        static_cast<unsigned long>(esp_random()),
        static_cast<unsigned long>(esp_random()),
        static_cast<unsigned long>(esp_random()),
        static_cast<unsigned long>(esp_random()));

    String payload = createApiReadingJson(
        reading,
        deviceId,
        String(readingId));

    if (payload.isEmpty())
    {
        SentinelLog::write(
            SentinelLog::Level::Error,
            "API",
            "Ölçüm JSON'u oluşturulamadı.");

        return false;
    }

    pending = PendingUpload{};
    pending.payload = payload;
    pending.occupied = true;

    return true;
}

void updateApiService()
{
    if (!pending.occupied ||
        pending.blocked ||
        WiFi.status() != WL_CONNECTED)
    {
        return;
    }

    if (pending.attempt > 0 &&
        millis() - pending.lastFailureMs < pending.retryDelayMs)
    {
        return;
    }

    pending.attempt++;

    SentinelLog::write(
        SentinelLog::Level::Debug,
        "API",
        "Gönderim denemesi: %lu",
        static_cast<unsigned long>(pending.attempt));

    WiFiClient client;
    HTTPClient http;

    http.setConnectTimeout(3000);
    http.setTimeout(5000);

    int statusCode = -1;

    if (http.begin(client, SENTINEL_API_URL))
    {
        http.addHeader("Content-Type", "application/json");

        http.addHeader(
            "Authorization",
            String("Bearer ") + SENTINEL_API_KEY);

        statusCode = http.POST(pending.payload);
    }

    http.end();

    if (statusCode == 200 || statusCode == 201)
    {
        SentinelLog::write(
            SentinelLog::Level::Info,
            "API",
            statusCode == 201
                ? "Ölçüm kaydedildi."
                : "Ölçüm zaten kayıtlı; gönderim tamamlandı.");

        pending = PendingUpload{};
        return;
    }

    // Yönlendirme ve kalıcı istek hatalarında inceleme gerekir.
    // 408 ve 429 için tekrar denemeye izin veriyoruz.
    if (statusCode >= 300 &&
        statusCode < 500 &&
        statusCode != 408 &&
        statusCode != 429)
    {
        pending.blocked = true;

        SentinelLog::write(
            SentinelLog::Level::Error,
            "API",
            "HTTP %d: Gönderim durduruldu; kayıt RAM'de korundu.",
            statusCode);

        return;
    }
    if (pending.attempt > 1)
    {
        const uint32_t doubled = pending.retryDelayMs * 2;
        pending.retryDelayMs = doubled > MAX_RETRY_MS ? MAX_RETRY_MS : doubled;
    }

    pending.lastFailureMs = millis();

    SentinelLog::write(
        SentinelLog::Level::Warning,
        "API",
        "Kod %d: Kayıt korundu; %lu sn sonra tekrar.",
        statusCode,
        static_cast<unsigned long>(pending.retryDelayMs / 1000));
}