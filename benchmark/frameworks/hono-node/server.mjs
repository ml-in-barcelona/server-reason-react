import { serve } from "@hono/node-server";
import { Hono } from "hono";
import React from "react";
import ReactDOMServer from "react-dom/server";
import * as scenarios from "../shared/scenarios.jsx";

const app = new Hono();
const PORT = process.env.PORT || 3003;

app.get("/", (c) => {
  const scenarioName = c.req.query("scenario") || "table100";
  const scenario = scenarios.scenarios[scenarioName];

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

app.get("/health", (c) => {
  return c.json({ status: "ok", framework: "hono-node", pid: process.pid });
});

app.get("/scenarios", (c) => {
  const list = Object.entries(scenarios.scenarios).map(([key, val]) => ({
    key,
    name: val.name,
    description: val.description,
  }));
  return c.json(list);
});

serve(
  {
    fetch: app.fetch,
    port: PORT,
  },
  (info) => {
    console.log(`[hono-node] Server listening on http://localhost:${info.port}`);
    console.log(`[hono-node] PID: ${process.pid}`);
  }
);

