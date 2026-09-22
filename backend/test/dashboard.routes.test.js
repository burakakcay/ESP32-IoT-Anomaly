const test = require("node:test");
const assert = require("node:assert/strict");

const request = require("supertest");

const { createApp } = require("../app");
const { createDashboardRouter } = require("../routes/dashboard.routes");

function createTestApp(getDashboardResponse) {
  const app = createApp();

  app.use("/api/dashboard", createDashboardRouter({ getDashboardResponse }));

  return app;
}

test("GET /api/dashboard ölçümleri ve analizi JSON olarak döndürür", async () => {
  const dashboard = {
    readings: [{ id: "reading-1", temperature: 25 }],
    anomalies: {
      device_id: "test-device",
      analyzedReadings: 40,
      anomalyReadings: 0,
      results: [],
    },
  };

  const app = createTestApp(async () => dashboard);

  const response = await request(app)
    .get("/api/dashboard")
    .expect("Content-Type", /json/)
    .expect(200);

  assert.deepEqual(response.body, dashboard);
});

test("GET /api/dashboard servisin 400 hata kodunu ve mesajını korur", async () => {
  const app = createTestApp(async () => {
    const error = new Error("Anomali analizi için en az 21 ölçüm gerekli.");
    error.statusCode = 400;
    throw error;
  });

  const response = await request(app).get("/api/dashboard").expect(400);

  assert.deepEqual(response.body, {
    error: "Anomali analizi için en az 21 ölçüm gerekli.",
  });
});

test("GET /api/dashboard durum kodu olmayan hatada 500 döndürür", async () => {
  const app = createTestApp(async () => {
    throw new Error("Test veri erişim hatası");
  });

  const response = await request(app).get("/api/dashboard").expect(500);

  assert.deepEqual(response.body, {
    error: "Test veri erişim hatası",
  });
});

test("GET /api/dashboard hata mesajı boşsa varsayılan mesajı döndürür", async () => {
  const app = createTestApp(async () => {
    throw new Error();
  });

  const response = await request(app).get("/api/dashboard").expect(500);

  assert.deepEqual(response.body, {
    error: "Dashboard verileri alınamadı.",
  });
});
