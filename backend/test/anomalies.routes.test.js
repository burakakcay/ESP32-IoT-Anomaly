const test = require("node:test");
const assert = require("node:assert/strict");

const request = require("supertest");

const { createApp } = require("../app");
const { createAnomaliesRouter } = require("../routes/anomalies.routes");
const { timeStamp } = require("node:console");
const { getAnomalyHistory } = require("../repositories/anomalies.repository");
const { deepEqual } = require("node:assert");

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

test("GET /api/anomalies/history kayıtlı geçmişi döndürür", async () => {
  const history = {
    device_id: "test-device",
    returnedCount: 1,
    results: [
      {
        id: "reading-1",
        timestamp: "2026-09-24T15:46:52",
      },
    ],
  };

  const app = createTestApp({
    getAnomalyHistory: async () => history,
  });

  const response = await request(app)
    .get("/api/anomalies/history")
    .expect("Content-Type", /json/)
    .expect(200);

  assert.deepEqual(response.body, history);
});

test("GET /api/anomalies/history boş geçmişte 200 döndürür", async () => {
  const history = {
    device_id: "test-device",
    returnedCount: 0,
    results: [],
  };

  const app = createTestApp({
    getAnomalyHistory: async () => history,
  });

  const response = await request(app).get("/api/anomalies/history").expect(200);

  assert.deepEqual(response.body, history);
});

test("GET /api/anomalies/history servis hatasında 500 döndürür", async (t) => {
  t.mock.method(console, "error", () => {});

  const app = createTestApp({
    getAnomalyHistory: async () => {
      throw new Error("Dahili veritabanı hatası");
    },
  });

  const response = await request(app).get("/api/anomalies/history").expect(500);

  assert.deepEqual(response.body, {
    error: "Anomali geçmişi alınamadı.",
  });
});

test("Geçmiş filtresi parametreleri servise aktarır", async () => {
  let receivedOptions;

  const history = {
    device_id: "test-device",
    returnedCount: 0,
    results: [],
    nextCursor: null,
  };

  const app = createTestApp({
    getAnomalyHistory: async (options) => {
      receivedOptions = options;
      return history;
    },
  });

  const response = await request(app)
    .get("/api/anomalies/history")
    .query({
      from: "2026-09-24",
      to: "2026-09-28",
      limit: "10",
      cursor: "reading-123",
    })
    .expect(200);

  assert.deepEqual(receivedOptions, {
    fromTimestamp: "2026-09-24T00:00:00",
    toTimestampExclusive: "2026-09-29T00:00:00",
    limit: 10,
    cursor: "reading-123",
  });

  assert.deepEqual(response.body, history);
});

test("Geçmiş sorgusu varsayılan olarak 20 kayıt ister", async () => {
  let receivedOptions;

  const app = createTestApp({
    getAnomalyHistory: async (options) => {
      receivedOptions = options;
      return { results: [], nextCursor: null };
    },
  });

  await request(app).get("/api/anomalies/history").expect(200);

  assert.deepEqual(receivedOptions, {
    fromTimestamp: undefined,
    toTimestampExclusive: undefined,
    limit: 20,
    cursor: undefined,
  });
});

test("Bitiş tarihi yıl sonunda sonraki yıla geçer", async () => {
  let receivedOptions;

  const app = createTestApp({
    getAnomalyHistory: async (options) => {
      receivedOptions = options;
      return { results: [], nextCursor: null };
    },
  });

  await request(app)
    .get("/api/anomalies/history")
    .query({ to: "2026-12-31" })
    .expect(200);

  assert.equal(receivedOptions.toTimestampExclusive, "2027-01-01T00:00:00");
});

const invalidHistoryQueries = [
  ["gerçekte olmayan tarih", { from: "2026-02-30" }],
  ["hatalı tarih biçimi", { from: "28.09.2026" }],
  ["ters tarih aralığı", { from: "2026-09-28", to: "2026-09-24" }],
  ["sıfır limit", { limit: "0" }],
  ["100 üzerinde limit", { limit: "101" }],
  ["ondalıklı limit", { limit: "2.5" }],
  ["boş cursor", { cursor: "" }],
  ["yol içeren cursor", { cursor: "readings/123" }],
];

for (const [description, query] of invalidHistoryQueries) {
  test(`Geçmiş sorgusu ${description} için 400 döndürür`, async () => {
    let serviceCalled = false;

    const app = createTestApp({
      getAnomalyHistory: async () => {
        serviceCalled = true;
        return { results: [] };
      },
    });

    const response = await request(app)
      .get("/api/anomalies/history")
      .query(query)
      .expect(400);

    assert.equal(serviceCalled, false);
    assert.equal(typeof response.body.error, "string");
    assert.ok(response.body.error.length > 0);
  });
}
