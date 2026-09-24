const path = require("node:path");

require("dotenv").config({
  path: path.join(__dirname, ".env"),
});

const { GoogleGenAI } = require("@google/genai");
const { analyzeAnomaliesWithAI } = require("./services/ai_service");
async function main() {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("backend/.env içinde GEMINI_API_KEY bulunamadı.");
  }

  const gemini = new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY,
  });

  // Temsili test verisi; Firestore'a kaydedilmez.
  const sampleAnomalies = [
    {
      timestamp: new Date().toISOString(),
      anomalyCount: 1,
      isAnomaly: true,
      measurements: {
        temperature: {
          value: 45,
          median: 25,
          mad: 0.5,
          robustZScore: 26.98,
          isAnomaly: true,
        },
      },
    },
  ];

  console.log("Temsili sıcaklık anomalisi Gemini'ye gönderiliyor...");

  const result = await analyzeAnomaliesWithAI(gemini, sampleAnomalies);

  console.log(JSON.stringify(result, null, 2));
}

main().catch((error) => {
  console.error("AI denemesi başarısız:", error.message);
  process.exitCode = 1;
});
