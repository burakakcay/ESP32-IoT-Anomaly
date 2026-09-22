const express = require("express");

function createReadingsRouter({ getReadings, getLatestReading }) {
  const router = express.Router();

  router.get("/", async (req, res) => {
    try {
      res.json(await getReadings());
    } catch (error) {
      console.error("Firestore okuma hatası:", error);
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

  return router;
}

module.exports = { createReadingsRouter };
