const { buildAnomalyResponse } = require("./anomaly_service");

function createSensorService({ getReadings, config, saveAnomalies }) {
  const {
    defaultDeviceId,
    readingLimit,
    dashboardReadingLimit,
    minBaselineSize,
    anomalyCacheDuration,
  } = config;

  let anomalyCache = null;
  let anomalyCacheTime = 0;

  async function getAnomalyResponse() {
    if (
      anomalyCache !== null &&
      Date.now() - anomalyCacheTime < anomalyCacheDuration
    ) {
      console.log("Anomaly cache kullanıldı.");
      return anomalyCache;
    }

    const readings = await getReadings(readingLimit);

    const analysis = buildAnomalyResponse(
      readings,
      defaultDeviceId,
      minBaselineSize,
    );

    await saveAnomalies(analysis.results);

    anomalyCache = analysis;
    anomalyCacheTime = Date.now();

    return anomalyCache;
  }

  async function getDashboardResponse() {
    const readings = await getReadings(dashboardReadingLimit);
    const anomalyReadings = readings.slice(0, readingLimit);

    const anomalies = buildAnomalyResponse(
      anomalyReadings,
      defaultDeviceId,
      minBaselineSize,
    );

    await saveAnomalies(anomalies.results);

    anomalyCache = anomalies;
    anomalyCacheTime = Date.now();

    return {
      readings,
      anomalies,
    };
  }

  return {
    getAnomalyResponse,
    getDashboardResponse,
  };
}

module.exports = { createSensorService };
