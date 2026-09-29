const { FieldValue } = require("firebase-admin/firestore");

function getSensorGroups(measurements) {
  const groups = new Set();

  for (const field of Object.keys(measurements)) {
    if (field === "temperature" || field === "humidity") {
      groups.add(field);
    } else if (["accel_x", "accel_y", "accel_z"].includes(field)) {
      groups.add("acceleration");
    } else if (["gyro_x", "gyro_y", "gyro_z"].includes(field)) {
      groups.add("gyroscope");
    }
  }

  return [...groups];
}

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
        sensorGroups: getSensorGroups(result.measurements),
        detectedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Firestore: ALREADY_EXISTS
      if (error.code === 6) continue;

      throw error;
    }
  }
}

async function getAnomalyHistory(
  db,
  deviceId,
  { fromTimestamp, toTimestampExclusive, limit = 20, cursor, sensor } = {},
) {
  const collection = db
    .collection("devices")
    .doc(deviceId)
    .collection("anomalies");

  let query = collection.orderBy("timestamp", "desc");

  if (sensor) {
    query = query.where("sensorGroups", "array-contains", sensor);
  }

  if (fromTimestamp) query = query.where("timestamp", ">=", fromTimestamp);

  if (toTimestampExclusive)
    query = query.where("timestamp", "<", toTimestampExclusive);

  if (cursor) {
    const cursorDocument = await collection.doc(cursor).get();
    const timestamp = cursorDocument.data()?.timestamp;
    const sensorGroups = cursorDocument.data()?.sensorGroups;
    const outsideSensor =
      sensor !== undefined &&
      (!Array.isArray(sensorGroups) || !sensorGroups.includes(sensor));

    const outsideRange =
      typeof timestamp !== "string" ||
      (fromTimestamp && timestamp < fromTimestamp) ||
      (toTimestampExclusive && timestamp >= toTimestampExclusive);

    if (!cursorDocument.exists || outsideRange || outsideSensor) {
      const error = new Error("Geçersiz sayfa işaretçisi");
      error.statusCode = 400;
      throw error;
    }

    query = query.startAfter(cursorDocument);
  }

  const snapshot = await query.limit(limit + 1).get();
  const hasMore = snapshot.docs.length > limit;
  const documents = snapshot.docs.slice(0, limit);

  const results = documents.map((doc) => {
    const data = doc.data();

    return {
      ...data,
      id: doc.id,
      detectedAt: data.detectedAt?.toDate().toISOString() ?? null,
    };
  });

  return {
    results,
    nextCursor: hasMore ? documents[documents.length - 1].id : null,
  };
}

module.exports = { saveAnomalies, getAnomalyHistory };
