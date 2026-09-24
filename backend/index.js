require("dotenv").config();
const config = require("./config/app_config");

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

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();
const app = createApp();

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

app.use("/api", requireAuth);

const gemini = process.env.GEMINI_API_KEY
  ? new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY })
  : null;

async function getReadings(limit = READING_LIMIT) {
  return fetchReadings(db, DEVICE_ID, limit);
}

async function getLatestReading() {
  return fetchLatestReadings(db, DEVICE_ID);
}

const { getAnomalyResponse, getDashboardResponse } = createSensorService({
  getReadings,
  config,
});

const { getAIResponse } = createAIResponseService({
  gemini,
  getAnomalyResponse,
  deviceId: DEVICE_ID,
  cacheDuration: AI_CACHE_DURATION,
});

app.use(
  "/api/readings",
  createReadingsRouter({ getReadings, getLatestReading }),
);

app.use("/api/dashboard", createDashboardRouter({ getDashboardResponse }));

app.use(
  "/api/anomalies",
  createAnomaliesRouter({ getAnomalyResponse, getAIResponse }),
);

app.listen(PORT, () => {
  console.log(`Backend başladı.`);
  console.log(`Readings: http://localhost:${PORT}/api/readings`);
  console.log(`Anomalies: http://localhost:${PORT}/api/anomalies`);
  console.log(`AI anomalies: http://localhost:${PORT}/api/anomalies/ai`);
});
