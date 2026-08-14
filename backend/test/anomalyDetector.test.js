const test = require("node:test");
const assert = require("node:assert/strict");

const { calculateAnomalyResults } = require("../anomalyDetector");

function createReading(index, overrides = {}) {
  return {
    timestamp: `2026-08-15T12:${String(index).padStart(2, "0")}:00`,
    accel_x: 100,
    accel_y: 200,
    accel_z: 300,
    gyro_x: 10,
    gyro_y: 20,
    gyro_z: 30,
    temperature: 25 + (index % 5) * 0.1,
    humidity: 50,
    ...overrides,
  };
}

function newestFirst(readings) {
  return [...readings].reverse();
}

test("normal ölçümlerde anomali oluşturmaz", () => {
  const readings = Array.from(
    { length: 60 },
    (_, index) => createReading(index),
  );

  const result = calculateAnomalyResults(newestFirst(readings), 20);

  assert.equal(result.analyzedReadings, 40);
  assert.equal(result.anomalyReadings, 0);
  assert.deepEqual(result.results, []);
});

test("aykırı sıcaklık değerini anomali olarak belirler", () => {
  const readings = Array.from(
    { length: 21 },
    (_, index) => createReading(index),
  );

  readings[20] = createReading(20, {
    temperature: 100,
  });

  const result = calculateAnomalyResults(newestFirst(readings), 20);

  assert.equal(result.analyzedReadings, 1);
  assert.equal(result.anomalyReadings, 1);
  assert.equal(result.results.length, 1);
  assert.equal(result.results[0].measurements.temperature.isAnomaly, true);
  assert.equal(result.results[0].measurements.temperature.value, 100);
});

test("MAD sıfır olduğunda ölçümü anomali kabul etmez", () => {
  const readings = Array.from(
    { length: 21 },
    (_, index) => createReading(index, { temperature: 25 }),
  );

  readings[20] = createReading(20, {
    temperature: 100,
  });

  const result = calculateAnomalyResults(newestFirst(readings), 20);

  assert.equal(result.analyzedReadings, 1);
  assert.equal(result.anomalyReadings, 0);
  assert.deepEqual(result.results, []);
});

test("60 ölçümün ilk 20 tanesini referans alıp 40 tanesini analiz eder", () => {
  const readings = Array.from(
    { length: 60 },
    (_, index) => createReading(index),
  );

  const result = calculateAnomalyResults(newestFirst(readings), 20);

  assert.equal(result.analyzedReadings, 40);
});