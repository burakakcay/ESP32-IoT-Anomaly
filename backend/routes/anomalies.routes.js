const express = require("express");

function createAnomaliesRouter({ getAnomalyResponse, getAIResponse }) {
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

  return router;
}

module.exports = { createAnomaliesRouter };
