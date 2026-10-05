const express = require("express");
const { validateReading } = require("../validators/reading.validator");

function createReadingIngestRouter({ requireDeviceAuth, repository }) {
  const router = express.Router();

  router.post("/", requireDeviceAuth, (req, res) => {
    const validation = validateReading(req.body);

    if (!validation.ok) {
      return res.status(400).json({
        error: validation.error,
      });
    }

    const reading = validation.reading;

    if (reading.deviceId !== req.authenticatedDeviceId) {
      return res.status(403).json({
        error: "Bu cihaz adına ölçüm gönderme yetkiniz yok.",
      });
    }

    try {
      const result = repository.saveReading(reading);

      if (result.status === "conflict") {
        return res.status(409).json({
          error: "Bu ölçüm kimliği farklı bir kayıt için kullanılmış.",
        });
      }

      return res.status(result.status === "created" ? 201 : 200).json({
        status: result.status,
        device_id: reading.deviceId,
        reading_id: reading.readingId,
      });
    } catch (error) {
      console.error("SQLite kayıt hatası:", error);

      return res.status(500).json({
        error: "Ölçüm kaydedilemedi.",
      });
    }
  });

  return router;
}

module.exports = { createReadingIngestRouter };
