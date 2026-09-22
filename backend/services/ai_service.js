async function analyzeAnomaliesWithAI(gemini, anomalyResults) {
  if (!anomalyResults.length) {
    return {
      summary: "Son ölçümlerde anomali tespit edilmedi.",
      severity: "normal",
      possibleCause: null,
      affectedSensors: [],
    };
  }

  const prompt = `Sen Sentinel isimli bir IoT sensör izleme sisteminin anomali analiz asistanısın.

Aşağıdaki anomaliler Robust Z-score yöntemiyle tespit edilmiştir.

Görevin:
1. Anomalilerin genel durumunu değerlendir.
2. Etkilenen sensörleri belirle.
3. Olası nedeni kesin teşhis koymadan, "muhtemel" olarak açıkla.
4. Ciddiyet seviyesini belirle.
5. Kısa ve anlaşılır bir açıklama üret.

İvme ve jiroskop değerlerini fiziksel hareket açısından; sıcaklık ve nemi ayrı değerlendir.
Veride olmayan bilgileri uydurma.
Olası nedenleri kesin ifade etme; "muhtemelen", "olası" veya "gösterebilir" ifadelerinden birini kullan.

Yalnızca aşağıdaki JSON biçiminde cevap ver:

{
  "summary": "kısa açıklama",
  "severity": "low | medium | high | critical",
  "possibleCause": "olası neden",
  "affectedSensors": ["gyro_y", "gyro_z"]
}

Anomali verileri:
${JSON.stringify(anomalyResults)}`;

  const response = await gemini.models.generateContent({
    model: "gemini-3.5-flash-lite",
    contents: prompt,
    config: {
      responseMimeType: "application/json",
    },
  });

  if (!response.text) {
    throw new Error("Gemini boş bir yanıt döndürdü.");
  }

  return JSON.parse(response.text);
}

module.exports = { analyzeAnomaliesWithAI };
