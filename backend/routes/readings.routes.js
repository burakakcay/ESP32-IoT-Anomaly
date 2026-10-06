const express = require("express");

function createReadingsRouter({
  getReadings,
  getLatestReading,
  getReadingsInRange,
}) {
  const router = express.Router();

  router.get("/", async (req, res) => {
    try {
      res.json(await getReadings());
    } catch (error) {
      console.error("Ölçüm okuma hatası:", error);
      res.status(500).json({ error: "Sensör verileri alınamadı." });
    }
  });

  router.get("/latest", async (req, res) => {
    try {
      const reading = await getLatestReading();

      if (reading === null) {
        return res.status(404).json({
          error: "Sensör verisi bulunamadı.",
        });
      }

      res.json(reading);
    } catch (error) {
      console.error("Son sensör verisi okuma hatası: ", error);
      res.status(500).json({
        error: "Son sensör verisi alınamadı.",
      });
    }
  });

  router.get("/history", async (req, res) => {
    const { fromMs, toMs } = req.query;

    const validParameter = (value) =>
      typeof value === "string" && /^\d{1,16}$/.test(value);

    if (!validParameter(fromMs) || !validParameter(toMs)) {
      return res.status(400).json({
        error: "fromMs ve toMs zamanları milisaniye olarak gönderilmelidir.",
      });
    }

    try {
      const result = await getReadingsInRange(Number(fromMs), Number(toMs));
      return res.json(result);
    } catch (error) {
      if ([400, 422, 503].includes(error.statusCode)) {
        return res.status(error.statusCode).json({
          error: error.message,
        });
      }

      console.error("Ölçüm geçmişi okuma hatası:", error);

      return res.status(500).json({
        error: "Ölçüm geçmişi alınamadı.",
      });
    }
  });

  return router;
}

module.exports = { createReadingsRouter };
