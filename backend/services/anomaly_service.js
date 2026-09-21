const { calculateAnomalyResults } = require("../anomalyDetector");

function buildAnomalyResponse(readings, deviceId, minBaselineSize) {
  if (readings.length < minBaselineSize + 1) {
    const error = new Error(
      `Anomali analizi için en az ${minBaselineSize + 1} ölçüm gerekli.`,
    );

    error.statusCode = 400;

    throw error;
  }

  const analysis = calculateAnomalyResults(readings, minBaselineSize);

  return {
    device_id: deviceId,
    ...analysis,
  };
}

module.exports = {
  buildAnomalyResponse,
};
