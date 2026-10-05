function validateReading(body) {
  function fail(message) {
    return { ok: false, error: message };
  }

  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return fail("İstek gövdesi bir JSON nesnesi olmalıdır.");
  }

  const validId = (value) =>
    typeof value === "string" && /^[A-Za-z0-9_-]{1,64}$/.test(value);

  if (!validId(body.device_id)) {
    return fail("device_id geçersiz");
  }

  if (!validId(body.reading_id)) {
    return fail("reading_id geçersiz");
  }

  // API için UTC ve milisaniye içeren tek bir tarih biçimi kullanıyoruz.
  // Örnek: 2026-10-05T12:30:00.000Z

  const timestampPattern = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;

  if (
    typeof body.timestamp !== "string" ||
    !timestampPattern.test(body.timestamp)
  ) {
    return fail("Timestamp UTC ISO biçiminde olmalıdır.");
  }

  const measuredAtMs = Date.parse(body.timestamp);

  if (
    !Number.isFinite(measuredAtMs) ||
    new Date(measuredAtMs).toISOString() !== body.timestamp
  ) {
    return fail("Timestamp geçerli bir tarih olmalıdır.");
  }

  const finiteNumber = (value) =>
    typeof value === "number" && Number.isFinite(value);

  const nullable = (check) => (value) => value === null || check(value);

  const rawSensorValue = (value) =>
    Number.isInteger(value) && value >= -32768 && value <= 32767;

  const nonNegativeNumber = (value) => finiteNumber(value) && value >= 0;

  const nonNegativeInteger = (value) =>
    Number.isSafeInteger(value) && value >= 0;

  const rules = {
    accel_x: rawSensorValue,
    accel_y: rawSensorValue,
    accel_z: rawSensorValue,
    gyro_x: rawSensorValue,
    gyro_y: rawSensorValue,
    gyro_z: rawSensorValue,

    temperature: nullable(finiteNumber),

    humidity: nullable(
      (value) => finiteNumber(value) && value >= 0 && value <= 100,
    ),

    last_rms_g: nullable(nonNegativeNumber),
    peak_g: nullable(nonNegativeNumber),

    vibration_interval_ms: (value) => Number.isSafeInteger(value) && value > 0,

    vibration_last_age_ms: nullable(nonNegativeInteger),
    vibration_window_count: nonNegativeInteger,

    vibration_sampling_error: (value) => typeof value === "boolean",

    vibration_saturated: (value) => typeof value === "boolean",
  };

  const payload = {
    device_id: body.device_id,
    reading_id: body.reading_id,
    timestamp: body.timestamp,
  };

  for (const [field, check] of Object.entries(rules)) {
    if (!Object.hasOwn(body, field)) {
      return fail(`${field} alanı eksik.`);
    }

    if (!check(body[field])) {
      return fail(`${field} alanı geçersiz.`);
    }

    payload[field] = body[field];
  }

  for (const field of Object.keys(body)) {
    if (!Object.hasOwn(payload, field)) {
      return fail(`Bilinmeyen alan: ${field}`);
    }
  }
  return {
    ok: true,
    reading: {
      deviceId: body.device_id,
      readingId: body.reading_id,
      measuredAtMs,
      payload,
    },
  };
}

module.exports = { validateReading };
