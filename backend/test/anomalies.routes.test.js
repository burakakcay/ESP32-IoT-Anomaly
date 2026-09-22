const test = require("node:test");
const assert = require("node:assert/strict");

const request = require("supertest");

const { createApp } = require("../app");
const { createAnomaliesRouter } = require("../routes/anomalies.routes");

function createTestApp(overrides = {}) {
  const app = createApp();

  app.use(
    "/api/anomalies",
    createAnomaliesRouter({
      getAnomalyResponse: async () => {
        throw new Error("Beklenmeyen getAnomalyResponse çağrısı");
      },
      getAIResponse: async () => {
        throw new Error("Beklenmeyen getAIResponse çağrısı");
      },
      ...overrides,
    }),
  );

  return app;
}

test("GET /api/anomalies analiz sonucunu JSON olarak döndürür", async () => {
  const analysis = {
    device_id: "test-device",
    analyzedReadings: 40,
    anomalyReadings: 0,
    results: [],
  };

  const app = createTestApp({
    getAnomalyResponse: async () => analysis,
  });

  const response = await request(app)
    .get("/api/anomalies")
    .expect("Content-Type", /json/)
    .expect(200);

  assert.deepEqual(response.body, analysis);
});

test("GET /api/anomalies servisin 400 hata kodunu korur", async () => {
  const app = createTestApp({
    getAnomalyResponse: async () => {
      const error = new Error("Analiz için yeterli ölçüm yok.");
      error.statusCode = 400;
      throw error;
    },
  });

  const response = await request(app).get("/api/anomalies").expect(400);

  assert.deepEqual(response.body, {
    error: "Analiz için yeterli ölçüm yok.",
  });
});

test("GET /api/anomalies beklenmeyen hatada 500 döndürür", async () => {
  const app = createTestApp({
    getAnomalyResponse: async () => {
      throw new Error("Test analiz hatası");
    },
  });

  const response = await request(app).get("/api/anomalies").expect(500);

  assert.deepEqual(response.body, {
    error: "Test analiz hatası",
  });
});

test("GET /api/anomalies/ai AI sonucunu JSON olarak döndürür", async () => {
  const analysis = {
    device_id: "test-device",
    analyzedReadings: 40,
    anomalyReadings: 0,
    anomalies: [],
    aiAnalysis: {
      summary: "Son ölçümlerde anomali tespit edilmedi.",
      severity: "normal",
      possibleCause: null,
      affectedSensors: [],
    },
  };

  const app = createTestApp({
    getAIResponse: async () => analysis,
  });

  const response = await request(app)
    .get("/api/anomalies/ai")
    .expect("Content-Type", /json/)
    .expect(200);

  assert.deepEqual(response.body, analysis);
});

test("GET /api/anomalies/ai servisin 503 hata kodunu korur", async () => {
  const message = "AI analizi yapılandırılmadı. GEMINI_API_KEY eksik.";

  const app = createTestApp({
    getAIResponse: async () => {
      const error = new Error(message);
      error.statusCode = 503;
      throw error;
    },
  });

  const response = await request(app).get("/api/anomalies/ai").expect(503);

  assert.deepEqual(response.body, { error: message });
});

test("GET /api/anomalies/ai beklenmeyen hatada 500 döndürür", async () => {
  const app = createTestApp({
    getAIResponse: async () => {
      throw new Error("Test AI servis hatası");
    },
  });

  const response = await request(app).get("/api/anomalies/ai").expect(500);

  assert.deepEqual(response.body, {
    error: "Test AI servis hatası",
  });
});
