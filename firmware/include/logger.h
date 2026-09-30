#pragma once

#include <Arduino.h>
#include <stdarg.h>
#include <stdio.h>

namespace SentinelLog
{
    enum class Level
    {
        Debug,
        Info,
        Warning,
        Error,
        Off
    };

    // Info hides measurements and successful write messages.
    constexpr Level MIN_LEVEL = Level::Debug;

    inline void write(Level level, const char *tag, const char *format, ...)
        __attribute__((format(printf, 3, 4)));

    inline void write(Level level, const char *tag, const char *format, ...)
    {
        if (level < MIN_LEVEL || level == Level::Off)
            return;

        const char *label = "INFO";
        switch (level)
        {
        case Level::Debug:
            label = "DEBUG";
            break;
        case Level::Warning:
            label = "WARN";
            break;
        case Level::Error:
            label = "ERROR";
            break;
        default:
            break;
        }

        char message[512];
        va_list args;
        va_start(args, format);
        const int length = vsnprintf(message, sizeof(message), format, args);
        va_end(args);

        if (length < 0)
        {
            Serial.println("[ERROR][LOG] Mesaj bicimlendirilemedi.");
            return;
        }

        Serial.printf("[%s][%s] %s%s\n", label, tag, message,
                      length >= static_cast<int>(sizeof(message)) ? " ...[kesildi]" : "");
    }
}