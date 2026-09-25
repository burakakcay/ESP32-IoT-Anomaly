const { FieldValue } = require("firebase-admin/firestore");

async function saveAnomalies(db, deviceId, results) {
  const collection = db
    .collection("devices")
    .doc(deviceId)
    .collection("anomalies");

  for (const result of results) {
    if (!result.isAnomaly) continue;

    if (!result.readingId) {
      throw new Error("Anomali kaydı için ölçüm kimliği gerekli.");
    }

    const document = collection.doc(result.readingId);

    try {
      await document.create({
        ...result,
        device_id: deviceId,
        detectedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Firestore: ALREADY_EXISTS
      if (error.code === 6) continue;

      throw error;
    }
  }
}

async function getAnomalyHistory(db, deviceId) {
  const snapshot = await db
    .collection("devices")
    .doc(deviceId)
    .collection("anomalies")
    .orderBy("timestamp", "desc")
    .limit(100)
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data();

    return {
      ...data,
      id: doc.id,
      detectedAt: data.detectedAt?.toDate().toISOString() ?? null,
    };
  });
}

module.exports = { saveAnomalies, getAnomalyHistory };
