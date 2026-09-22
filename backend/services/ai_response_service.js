const { analyzeAnomaliesWithAI } = require("./ai_service");

function createAIResponseService({
  gemini,
  getAnomalyResponse,
  deviceId,
  cacheDuration,
}) {
  let aiCache = null;
  let aiCacheTime = 0;

  async function getAIResponse() {
    if (!gemini) {
      const error = new Error(
        "AI analizi yapılandırılmadı. GEMINI_API_KEY eksik.",
      );
      error.statusCode = 503;
      throw error;
    }

    if (aiCache !== null && Date.now() - aiCacheTime < cacheDuration) {
      console.log("AI anomaly cache kullanıldı.");
      return aiCache;
    }

    const anomalyResponse = await getAnomalyResponse();
    const recentAnomalies = anomalyResponse.results.slice(-10);
    const aiAnalysis = await analyzeAnomaliesWithAI(gemini, recentAnomalies);

    aiCache = {
      device_id: deviceId,
      analyzedReadings: anomalyResponse.analyzedReadings,
      anomalyReadings: anomalyResponse.anomalyReadings,
      anomalies: recentAnomalies,
      aiAnalysis,
    };
    aiCacheTime = Date.now();

    return aiCache;
  }

  return { getAIResponse };
}

module.exports = { createAIResponseService };
