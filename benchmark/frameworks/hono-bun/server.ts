/**
 * Hono + Bun + React SSR Benchmark Server
 */

import { Hono } from "hono";
import React from "react";
import ReactDOMServer from "react-dom/server";
import * as scenarios from "../shared/scenarios.jsx";

const app = new Hono();
const PORT = Number(process.env.PORT) || 3004;

// Scenario selection via query param
app.get("/", (c) => {
  const scenarioName = c.req.query("scenario") || "table100";
  const scenario = scenarios.scenarios[scenarioName as keyof typeof scenarios.scenarios];

  if (!scenario) {
    c.status(404);
    return c.text(`Unknown scenario: ${scenarioName}`);
  }

  const Component = scenario.component;
  const html = ReactDOMServer.renderToString(React.createElement(Component));

  return c.html(
    `<!DOCTYPE html><html><head><title>Benchmark</title></head><body><div id="root">${html}</div></body></html>`
  );
});

// Health check
app.get("/health", (c) => {
  return c.json({ status: "ok", framework: "hono-bun", pid: process.pid });
});

// List available scenarios
app.get("/scenarios", (c) => {
  const list = Object.entries(scenarios.scenarios).map(([key, val]) => ({
    key,
    name: val.name,
    description: val.description,
  }));
  return c.json(list);
});

export default {
  port: PORT,
  fetch: app.fetch,
};

console.log(`[hono-bun] Server listening on http://localhost:${PORT}`);
console.log(`[hono-bun] PID: ${process.pid}`);

