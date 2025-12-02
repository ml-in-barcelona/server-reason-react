/**
 * Node.js + Fastify + React SSR Benchmark Server
 */

import Fastify from "fastify";
import React from "react";
import ReactDOMServer from "react-dom/server";
import * as scenarios from "../shared/scenarios.jsx";

const fastify = Fastify({
  logger: false,
});

const PORT = process.env.PORT || 3002;

// Scenario selection via query param
fastify.get("/", async (request, reply) => {
  const scenarioName = request.query.scenario || "table100";
  const scenario = scenarios.scenarios[scenarioName];

  if (!scenario) {
    reply.code(404);
    return `Unknown scenario: ${scenarioName}`;
  }

  const Component = scenario.component;
  const html = ReactDOMServer.renderToString(React.createElement(Component));

  reply.type("text/html");
  return `<!DOCTYPE html><html><head><title>Benchmark</title></head><body><div id="root">${html}</div></body></html>`;
});

// Health check
fastify.get("/health", async () => {
  return { status: "ok", framework: "node-fastify", pid: process.pid };
});

// List available scenarios
fastify.get("/scenarios", async () => {
  return Object.entries(scenarios.scenarios).map(([key, val]) => ({
    key,
    name: val.name,
    description: val.description,
  }));
});

const start = async () => {
  try {
    await fastify.listen({ port: PORT, host: "0.0.0.0" });
    console.log(`[node-fastify] Server listening on http://localhost:${PORT}`);
    console.log(`[node-fastify] PID: ${process.pid}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();

