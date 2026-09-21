async function getReadings(db, deviceId, limit) {
  const snapshot = await db
    .collection("devices")
    .doc(deviceId)
    .collection("readings")
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

async function getLatestReading(db, deviceId) {
  const readings = await getReadings(db, deviceId, 1);

  return readings[0] || null;
}

module.exports = {
  getReadings,
  getLatestReading,
};
