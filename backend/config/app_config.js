module.exports = {
  port: Number(process.env.PORT || 3000),

  defaultDeviceId: process.env.DEVICE_ID || "ESP32_Sensor_Node_001",

  readingLimit: 60,
  dashboardReadingLimit: 240,
  minBaselineSize: 20,

  anomalyCacheDuration: 10_000,
  aiCacheDuration: 60_000,
};
