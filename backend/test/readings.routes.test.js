const test = require("node:test");
const assert = require("node:assert/strict");

const request = require("supertest");

const { createApp } = require("../app");
const { createReadingsRouter } = require("../routes/readings.routes");

function createTestApp(overrides = {}) {
  const app = createApp();

  const dependencies = {
    getReadings: async () => {
      throw new Error("Beklenmeyen getReadings çağrısı");
    },
    getLatestReading: async () => {
      throw new Error("Beklenmeyen getLatestReading çağrısı");
    },
    ...overrides,
  };

  app.use("/api/readings", createReadingsRouter(dependencies));

  return app;
}

test("GET /api/readings ölçüm listesini JSON olarak döndürür", async () => {
  const readings = [
    { id: "reading-2", temperature: 25 },
    { id: "reading-1", temperature: 24 },
  ];

  const app = createTestApp({
    getReadings: async () => readings,
  });

  const response = await request(app)
    .get("/api/readings")
    .expect("Content-Type", /json/)
    .expect(200);

  assert.deepEqual(response.body, readings);
});

test("GET /api/readings veri yoksa boş liste döndürür", async () => {
  const app = createTestApp({
    getReadings: async () => [],
  });

  const response = await request(app).get("/api/readings").expect(200);

  assert.deepEqual(response.body, []);
});

test("GET /api/readings servis hatasında 500 döndürür", async () => {
  const app = createTestApp({
    getReadings: async () => {
      throw new Error("Test veri erişim hatası");
    },
  });

  const response = await request(app).get("/api/readings").expect(500);

  assert.deepEqual(response.body, {
    error: "Sensör verileri alınamadı.",
  });
});

test("GET /api/readings/latest son ölçümü döndürür", async () => {
  const reading = { id: "reading-2", temperature: 25 };

  const app = createTestApp({
    getLatestReading: async () => reading,
  });

  const response = await request(app)
    .get("/api/readings/latest")
    .expect("Content-Type", /json/)
    .expect(200);

  assert.deepEqual(response.body, reading);
});

test("GET /api/readings/latest veri yoksa 404 döndürür", async () => {
  const app = createTestApp({
    getLatestReading: async () => null,
  });

  const response = await request(app).get("/api/readings/latest").expect(404);

  assert.deepEqual(response.body, {
    error: "Sensör verisi bulunamadı.",
  });
});

test("GET /api/readings/latest servis hatasında 500 döndürür", async () => {
  const app = createTestApp({
    getLatestReading: async () => {
      throw new Error("Test veri erişim hatası");
    },
  });

  const response = await request(app).get("/api/readings/latest").expect(500);

  assert.deepEqual(response.body, {
    error: "Son sensör verisi alınamadı.",
  });
});
