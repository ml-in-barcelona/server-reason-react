/**
 * Node.js + Express + React SSR Benchmark Server
 */

import express from "express";
import React from "react";
import ReactDOMServer from "react-dom/server";
import * as scenarios from "../shared/scenarios.jsx";

const app = express();
const PORT = process.env.PORT || 3001;

// Scenario selection via query param
app.get("/", (req, res) => {
  const scenarioName = req.query.scenario || "table100";
  const scenario = scenarios.scenarios[scenarioName];

  if (!scenario) {
    return res.status(404).send(`Unknown scenario: ${scenarioName}`);
  }

  const Component = scenario.component;
  const html = ReactDOMServer.renderToString(React.createElement(Component));

  res.setHeader("Content-Type", "text/html");
  res.send(`<!DOCTYPE html><html><head><title>Benchmark</title></head><body><div id="root">${html}</div></body></html>`);
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", framework: "node-express", pid: process.pid });
});

// List available scenarios
app.get("/scenarios", (req, res) => {
  const list = Object.entries(scenarios.scenarios).map(([key, val]) => ({
    key,
    name: val.name,
    description: val.description,
  }));
  res.json(list);
});

app.listen(PORT, () => {
  console.log(`[node-express] Server listening on http://localhost:${PORT}`);
  console.log(`[node-express] PID: ${process.pid}`);
});

