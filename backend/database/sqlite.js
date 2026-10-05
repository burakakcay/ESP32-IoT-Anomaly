const { DatabaseSync } = require("node:sqlite");
const { mkdirSync } = require("node:fs");
const path = require("node:path");

function openDatabase(
  databasePath = path.join(__dirname, "..", "data", "sentinel.sqlite"),
) {
  if (databasePath !== ":memory:") {
    mkdirSync(path.dirname(databasePath), { recursive: true });
  }

  const db = new DatabaseSync(databasePath);

  db.exec(`
    PRAGMA journal_mode = WAL;
    PRAGMA busy_timeout = 5000;

    CREATE TABLE IF NOT EXISTS readings (
      device_id TEXT NOT NULL,
      reading_id TEXT NOT NULL,
      measured_at_ms INTEGER NOT NULL,
      received_at_ms INTEGER NOT NULL,
      payload_json TEXT NOT NULL,

      PRIMARY KEY (device_id, reading_id)
    );

    CREATE INDEX IF NOT EXISTS idx_readings_device_time
      ON readings (device_id, measured_at_ms DESC);
  `);

  return db;
}

module.exports = { openDatabase };
