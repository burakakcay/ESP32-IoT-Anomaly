const express = require("express");
const cors = require("cors");

function createApp() {
  const app = express();

  app.use(
    cors({
      origin: "http://localhost:5000",
      methods: ["GET"],
      allowedHeaders: ["Authorization", "Content-Type"],
    }),
  );

  app.use(express.json);

  return app;
}

module.exports = { createApp };
