const { getAuth } = require("firebase-admin/auth");

async function requireAuth(req, res, next) {
  const authorization = req.get("Authorization");

  if (!authorization?.startsWith("Bearer ")) {
    return res.status(401).json({
      error: "Kimlik doğrulaması gerekli.",
    });
  }

  const token = authorization.slice(7).trim();

  if (!token) {
    return res.status(401).json({
      error: "Kimlik doğrulaması gerekli.",
    });
  }

  try {
    req.user = await getAuth().verifyIdToken(token);
  } catch (error) {
    console.error("Kimlik doğrulama başarısız:", error.code);

    return res.status(401).json({
      error: "Geçersiz veya süresi dolmuş oturum.",
    });
  }

  const allowedUserUid = process.env.ALLOWED_USER_UID?.trim();

  if (!allowedUserUid) {
    return res.status(503).json({
      error: "API erişimi yapılandırılmadı.",
    });
  }

  if (req.user.uid !== allowedUserUid) {
    return res.status(403).json({
      error: "Bu cihaza erişim yetkiniz yok.",
    });
  }

  next();
}

module.exports = { requireAuth };
