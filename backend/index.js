require("dotenv").config();
const config = require("./config/app_config");

if (!["firestore", "sqlite"].includes(config.readingsSource)) {
  throw new Error("READINGS_SOURCE firestore veya sqlite olmalıdır.");
}

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { GoogleGenAI } = require("@google/genai");
const serviceAccount = require(
  process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "./serviceAccountKey.json",
);

const {
  port: PORT,
  defaultDeviceId: DEVICE_ID,
  readingLimit: READING_LIMIT,
  aiCacheDuration: AI_CACHE_DURATION,
} = config;

const {
  getReadings: fetchReadings,
  getLatestReading: fetchLatestReadings,
} = require("./repositories/readings.repository");

const { createApp } = require("./app");

const { createSensorService } = require("./services/sensor_service");
const { createAIResponseService } = require("./services/ai_response_service");

const { createReadingsRouter } = require("./routes/readings.routes");
const { createDashboardRouter } = require("./routes/dashboard.routes");
const { createAnomaliesRouter } = require("./routes/anomalies.routes");
const { requireAuth } = require("./middleware/auth.middleware");
const {
  saveAnomalies: persistAnomalies,
  getAnomalyHistory: fetchAnomalyHistory,
} = require("./repositories/anomalies.repository");

const { openDatabase } = require("./database/sqlite");

const {
  createSQLiteReadingsRepository,
} = require("./repositories/sqlite_readings.repository");

const { createDeviceAuth } = require("./middleware/device_auth.middleware");

const {
  createReadingIngestRouter,
} = require("./routes/readings_ingest.routes");

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();
const app = createApp();

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

const sqliteDb = openDatabase();

const sqliteReadingsRepository = createSQLiteReadingsRepository(sqliteDb);

const requireDeviceAuth = createDeviceAuth({
  deviceId: DEVICE_ID,
  apiKey: process.env.DEVICE_API_KEY,
});

app.use(
  "/api/readings",
  createReadingIngestRouter({
    requireDeviceAuth,
    repository: sqliteReadingsRepository,
  }),
);

app.use("/api", requireAuth);

const gemini = process.env.GEMINI_API_KEY
  ? new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY })
  : null;

async function getReadings(limit = READING_LIMIT) {
  if (config.readingsSource === "sqlite") {
    return sqliteReadingsRepository.getReadings(DEVICE_ID, limit);
  }
  return fetchReadings(db, DEVICE_ID, limit);
}

async function getLatestReading() {
  if (config.readingsSource === "sqlite") {
    return sqliteReadingsRepository.getLatestReading(DEVICE_ID);
  }
  return fetchLatestReadings(db, DEVICE_ID);
}

async function getReadingsInRange(fromMs, toMs) {
  if (config.readingsSource !== "sqlite") {
    const error = new Error(
      "Tarih aralığı sorgusu için SQLite kaynağı seçilmelidir.",
    );
    error.statusCode = 503;
    throw error;
  }

  const readings = sqliteReadingsRepository.getReadingsInRange(
    DEVICE_ID,
    fromMs,
    toMs,
  );

  return {
    device_id: DEVICE_ID,
    from_ms: fromMs,
    to_ms: toMs,
    returnedCount: readings.length,
    readings,
  };
}

async function getAnomalyHistory(options = {}) {
  const { results, nextCursor } = await fetchAnomalyHistory(
    db,
    DEVICE_ID,
    options,
  );

  return {
    device_id: DEVICE_ID,
    returnedCount: results.length,
    results,
    nextCursor,
  };
}

const { getAnomalyResponse, getDashboardResponse } = createSensorService({
  getReadings,
  config,
  saveAnomalies: (results) => persistAnomalies(db, DEVICE_ID, results),
});

const { getAIResponse } = createAIResponseService({
  gemini,
  getAnomalyResponse,
  deviceId: DEVICE_ID,
  cacheDuration: AI_CACHE_DURATION,
});

app.use(
  "/api/readings",
  createReadingsRouter({ getReadings, getLatestReading, getReadingsInRange }),
);

app.use("/api/dashboard", createDashboardRouter({ getDashboardResponse }));

app.use(
  "/api/anomalies",
  createAnomaliesRouter({
    getAnomalyResponse,
    getAIResponse,
    getAnomalyHistory,
  }),
);

app.listen(PORT, () => {
  console.log(`Backend başladı.`);
  console.log(`Readings: http://localhost:${PORT}/api/readings`);
  console.log(`Anomalies: http://localhost:${PORT}/api/anomalies`);
  console.log(`AI anomalies: http://localhost:${PORT}/api/anomalies/ai`);
});
