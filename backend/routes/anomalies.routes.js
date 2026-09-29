const express = require("express");

function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

function parseDate(value, name) {
  if (value === undefined) return undefined;

  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw badRequest(`${name}, YYYY-MM-DD biçiminde olmalı.`);
  }

  const date = new Date(`${value}T00:00:00.000Z`);

  if (
    !Number.isFinite(date.getTime()) ||
    date.toISOString().slice(0, 10) !== value
  ) {
    throw badRequest("${name} geçerli bir tarih olmalı.");
  }
  return date;
}

function parseHistoryOptions(query) {
  const from = parseDate(query.from, "from");
  const to = parseDate(query.to, "to");

  const sensor = query.sensor;
  const allowedSensors = [
    "temperature",
    "humidity",
    "acceleration",
    "gyroscope",
  ];
  if (
    sensor !== undefined &&
    (typeof sensor !== "string" || !allowedSensors.includes(sensor))
  ) {
    throw badRequest("Geçersiz sensör filtresi.");
  }

  if (from && to && from > to) {
    throw badRequest("Başlangıç tarihi bitiş tarihinden sonra olamaz.");
  }

  const rawLimit = query.limit ?? "20";

  if (typeof rawLimit !== "string" || !/^\d+$/.test(rawLimit)) {
    throw badRequest("limit, 1 ile 100 arasında bir tam sayı olmalı.");
  }

  const limit = Number(rawLimit);

  if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
    throw badRequest("limit, 1 ile 100 arasında bir tam sayı olmalı.");
  }

  const cursor = query.cursor;

  if (
    cursor !== undefined &&
    (typeof cursor !== "string" ||
      cursor.trim().length === 0 ||
      cursor.includes("/") ||
      cursor === "." ||
      cursor === ".." ||
      /^__.*__$/.test(cursor) ||
      Buffer.byteLength(cursor, "utf8") > 1500)
  ) {
    throw badRequest("Geçersiz sayfa işaretçisi.");
  }

  let toTimestampExclusive;

  if (to) {
    const nextDay = new Date(to);
    nextDay.setUTCDate(nextDay.getUTCDate() + 1);

    if (nextDay.getUTCFullYear() > 9999) {
      throw badRequest("Bitiş tarihi desteklenen aralığın dışında.");
    }

    toTimestampExclusive = `${nextDay.toISOString().slice(0, 10)}T00:00:00`;
  }

  return {
    fromTimestamp: from
      ? `${from.toISOString().slice(0, 10)}T00:00:00`
      : undefined,
    toTimestampExclusive,
    limit,
    cursor,
    ...(sensor !== undefined ? { sensor } : {}),
  };
}

function createAnomaliesRouter({
  getAnomalyResponse,
  getAIResponse,
  getAnomalyHistory,
}) {
  const router = express.Router();

  router.get("/", async (req, res) => {
    try {
      res.json(await getAnomalyResponse());
    } catch (error) {
      console.error("Anomali analizi hatası: ", error);

      res
        .status(error.statusCode || 500)
        .json({ error: error.message || "Anomali analizi yapılamadı. " });
    }
  });

  router.get("/ai", async (req, res) => {
    try {
      res.json(await getAIResponse());
    } catch (error) {
      console.error("AI anomali analizi hatası: ", error);

      res
        .status(error.statusCode || 500)
        .json({ error: error.message || "AI anomali analizi yapılamadı." });
    }
  });

  router.get("/history", async (req, res) => {
    try {
      const options = parseHistoryOptions(req.query);
      const response = await getAnomalyHistory(options);

      res.json(response);
    } catch (error) {
      if (error.statusCode === 400) {
        return res.status(400).json({
          error: error.message,
        });
      }

      console.error("Anomali geçmişi alınamadı:", error);

      res.status(500).json({
        error: "Anomali geçmişi alınamadı.",
      });
    }
  });

  return router;
}

module.exports = { createAnomaliesRouter };
