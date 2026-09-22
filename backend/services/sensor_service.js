const { buildAnomalyResponse } = require("./anomaly_service");

function createSensorService({ getReadings, config }) {
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

    anomalyCache = buildAnomalyResponse(
      readings,
      defaultDeviceId,
      minBaselineSize,
    );
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
