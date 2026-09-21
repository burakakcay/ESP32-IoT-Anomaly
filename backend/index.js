require("dotenv").config();

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const express = require("express");
const { GoogleGenAI } = require("@google/genai");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();
const app = express();
const {
  port: PORT,
  defaultDeviceId: DEVICE_ID,
  readingLimit: READING_LIMIT,
  dashboardReadingLimit: DASHBOARD_READING_LIMIT,
  minBaselineSize: MIN_BASELINE_SIZE,
  anomalyCacheDuration: ANOMALY_CACHE_DURATION,
  aiCacheDuration: AI_CACHE_DURATION,
} = require("./config/app_config");

const {
  getReadings: fetchReadings,
  getLatestReading: fetchLatestReadings,
} = require("./repositories/readings.repository");

const { buildAnomalyResponse } = require("./services/anomaly_service");

let anomalyCache = null;
let anomalyCacheTime = 0;
let aiCache = null;
let aiCacheTime = 0;

const gemini = process.env.GEMINI_API_KEY
  ? new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY })
  : null;

app.use(express.json());

async function getReadings(limit = READING_LIMIT) {
  return fetchReadings(db, DEVICE_ID, limit);
}

async function getLatestReading() {
  return fetchLatestReadings(db, DEVICE_ID);
}

async function getAnomalyResponse() {
  if (
    anomalyCache !== null &&
    Date.now() - anomalyCacheTime < ANOMALY_CACHE_DURATION
  ) {
    console.log("Anomaly cache kullanıldı.");
    return anomalyCache;
  }

  console.log("Anomaly cache süresi doldu. Firestore okunuyor...");

  const readings = await getReadings();

  anomalyCache = buildAnomalyResponse(readings, DEVICE_ID, MIN_BASELINE_SIZE);
  anomalyCacheTime = Date.now();

  return anomalyCache;
}

async function getDashboardResponse() {
  const readings = await getReadings(DASHBOARD_READING_LIMIT);

  // Anomali hesabında yalnızca en yeni 60 ölçümü kullan.
  const anomalyReadings = readings.slice(0, READING_LIMIT);
  const anomalies = buildAnomalyResponse(
    anomalyReadings,
    DEVICE_ID,
    MIN_BASELINE_SIZE,
  );
  anomalyCache = anomalies;
  anomalyCacheTime = Date.now();

  return {
    readings,
    anomalies,
  };
}

async function analyzeAnomaliesWithAI(anomalyResults) {
  if (!anomalyResults.length) {
    return {
      summary: "Son ölçümlerde anomali tespit edilmedi.",
      severity: "normal",
      possibleCause: null,
      affectedSensors: [],
    };
  }

  const prompt = `Sen Sentinel isimli bir IoT sensör izleme sisteminin anomali analiz asistanısın.

Aşağıdaki anomaliler Robust Z-score yöntemiyle tespit edilmiştir.

Görevin:
1. Anomalilerin genel durumunu değerlendir.
2. Etkilenen sensörleri belirle.
3. Olası nedeni kesin teşhis koymadan, "muhtemel" olarak açıkla.
4. Ciddiyet seviyesini belirle.
5. Kısa ve anlaşılır bir açıklama üret.

İvme ve jiroskop değerlerini fiziksel hareket açısından; sıcaklık ve nemi ayrı değerlendir.
Veride olmayan bilgileri uydurma.
Olası nedenleri kesin ifade etme; "muhtemelen", "olası" veya "gösterebilir" ifadelerinden birini kullan.

Yalnızca aşağıdaki JSON biçiminde cevap ver:

{
  "summary": "kısa açıklama",
  "severity": "low | medium | high | critical",
  "possibleCause": "olası neden",
  "affectedSensors": ["gyro_y", "gyro_z"]
}

Anomali verileri:
${JSON.stringify(anomalyResults)}`;

  const response = await gemini.models.generateContent({
    model: "gemini-3.5-flash-lite",
    contents: prompt,
    config: {
      responseMimeType: "application/json",
    },
  });

  if (!response.text) {
    throw new Error("Gemini boş bir yanıt döndürdü.");
  }

  return JSON.parse(response.text);
}

app.get("/api/dashboard", async (req, res) => {
  try {
    res.json(await getDashboardResponse());
  } catch (error) {
    console.error("Dashboard verileri alınamadı:", error);

    res
      .status(error.statusCode || 500)
      .json({ error: error.message || "Dashboard verileri alınamadı." });
  }
});

app.get("/api/readings", async (req, res) => {
  try {
    res.json(await getReadings());
  } catch (error) {
    console.error("Firestore okuma hatası:", error);
    res.status(500).json({ error: "Sensör verileri alınamadı." });
  }
});

app.get("/api/readings/latest", async (req, res) => {
  try {
    const reading = await getLatestReading();

    if (reading === null) {
      return res.status(404).json({
        error: "Sensör verisi bulunamadı.",
      });
    }

    res.json(reading);
  } catch (error) {
    console.error("Son sensör verisi okuma hatası:", error);

    res.status(500).json({
      error: "Son sensör verisi alınamadı.",
    });
  }
});

app.get("/api/anomalies", async (req, res) => {
  try {
    res.json(await getAnomalyResponse());
  } catch (error) {
    console.error("Anomali analizi hatası:", error);
    res
      .status(error.statusCode || 500)
      .json({ error: error.message || "Anomali analizi yapılamadı." });
  }
});

app.get("/api/anomalies/ai", async (req, res) => {
  if (!gemini) {
    return res
      .status(503)
      .json({ error: "AI analizi yapılandırılmadı. GEMINI_API_KEY eksik." });
  }
  if (aiCache !== null && Date.now() - aiCacheTime < AI_CACHE_DURATION) {
    console.log("AI anomaly cache kullanıldı.");
    return res.json(aiCache);
  }

  try {
    const anomalyResponse = await getAnomalyResponse();
    const recentAnomalies = anomalyResponse.results.slice(-10);
    const aiAnalysis = await analyzeAnomaliesWithAI(recentAnomalies);
    aiCache = {
      device_id: DEVICE_ID,
      analyzedReadings: anomalyResponse.analyzedReadings,
      anomalyReadings: anomalyResponse.anomalyReadings,
      anomalies: recentAnomalies,
      aiAnalysis,
    };
    aiCacheTime = Date.now();
    res.json(aiCache);
  } catch (error) {
    console.error("AI anomali analizi hatası:", error);
    res
      .status(error.statusCode || 500)
      .json({ error: error.message || "AI anomali analizi yapılamadı." });
  }
});

app.listen(PORT, () => {
  console.log(`Backend başladı.`);
  console.log(`Readings: http://localhost:${PORT}/api/readings`);
  console.log(`Anomalies: http://localhost:${PORT}/api/anomalies`);
  console.log(`AI anomalies: http://localhost:${PORT}/api/anomalies/ai`);
});
