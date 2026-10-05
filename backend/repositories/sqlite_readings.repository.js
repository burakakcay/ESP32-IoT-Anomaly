const { isDeepStrictEqual } = require("node:util");

function createSQLiteReadingsRepository(db) {
  const insertReading = db.prepare(`
    INSERT INTO readings (
      device_id,
      reading_id,
      measured_at_ms,
      received_at_ms,
      payload_json
    )
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT (device_id, reading_id) DO NOTHING
  `);

  const findReading = db.prepare(`
    SELECT measured_at_ms, payload_json
    FROM readings
    WHERE device_id = ? AND reading_id = ?
  `);

  const listReadings = db.prepare(`
    SELECT reading_id, payload_json
    FROM readings
    WHERE device_id = ?
    ORDER BY measured_at_ms DESC, reading_id DESC
    LIMIT ?
  `);

  function saveReading({ deviceId, readingId, measuredAtMs, payload }) {
    const result = insertReading.run(
      deviceId,
      readingId,
      measuredAtMs,
      Date.now(),
      JSON.stringify(payload),
    );

    if (result.changes === 1) {
      return { status: "created" };
    }

    const existing = findReading.get(deviceId, readingId);

    const sameReading =
      existing.measured_at_ms === measuredAtMs &&
      isDeepStrictEqual(JSON.parse(existing.payload_json), payload);

    if (sameReading) {
      return { status: "duplicate" };
    }
    return { status: "conflict" };
  }

  function getReadings(deviceId, limit = 60) {
    if (!Number.isSafeInteger(limit) || limit < 1 || limit > 1000) {
      throw new RangeError("Kayıt limiti 1-1000 arasında olmalıdır.");
    }

    return listReadings.all(deviceId, limit).map((row) => ({
      ...JSON.parse(row.payload_json),
      id: row.reading_id,
    }));
  }

  function getLatestReading(deviceId) {
    return getReadings(deviceId, 1)[0] ?? null;
  }

  return { saveReading, getReadings, getLatestReading };
}

module.exports = {
  createSQLiteReadingsRepository: createSQLiteReadingsRepository,
};
