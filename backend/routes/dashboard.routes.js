const express = require("express");

function createDashboardRouter({ getDashboardResponse }) {
  const router = express.Router();

  router.get("/", async (req, res) => {
    try {
      res.json(await getDashboardResponse());
    } catch (error) {
      console.error("Dashboard verileri alınamadı.", error);

      res
        .status(error.statusCode || 500)
        .json({ error: error.message || "Dashboard verileri alınamadı." });
    }
  });

  return router;
}

module.exports = { createDashboardRouter };
