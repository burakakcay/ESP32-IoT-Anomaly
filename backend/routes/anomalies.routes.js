const express = require("express");

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
      res.json(await getAnomalyHistory());
    } catch (error) {
      console.error("Anomali geçmişi alınamadı:", error);

      res.status(500).json({
        error: "Anomali geçmişi alınamadı.",
      });
    }
  });

  return router;
}

module.exports = { createAnomaliesRouter };
