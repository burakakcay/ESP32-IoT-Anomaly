const { timingSafeEqual } = require("node:crypto");

function createDeviceAuth({ deviceId, apiKey }) {
  const validConfiguration =
    typeof deviceId === "string" &&
    /^[A-Za-z0-9_-]{1,64}$/.test(deviceId) &&
    typeof apiKey === "string" &&
    /^[a-f0-9]{64}$/i.test(apiKey);

  const expectedKey = validConfiguration ? Buffer.from(apiKey, "hex") : null;

  return function requireDeviceAuth(req, res, next) {
    if (!validConfiguration) {
      return res.status(503).json({
        error: "Cihaz erişimi yapılandırılamadı.",
      });
    }

    const authorization = req.get("Authorization");

    const match =
      typeof authorization === "string"
        ? /^Bearer ([a-f0-9]{64})$/i.exec(authorization)
        : null;

    if (!match) {
      return res.status(401).json({
        error: "Geçerli bir cihaz anahtarı gerekli.",
      });
    }

    const suppliedKey = Buffer.from(match[1], "hex");

    if (!timingSafeEqual(suppliedKey, expectedKey)) {
      return res.status(401).json({
        error: "Geçerli bir cihaz anahtarı gerekli.",
      });
    }

    req.authenticatedDeviceId = deviceId;
    next();
  };
}

module.exports = { createDeviceAuth };
