/**
 * Bun Native + React SSR Benchmark Server
 */

import React from "react";
import ReactDOMServer from "react-dom/server";
import * as scenarios from "../shared/scenarios.jsx";

const PORT = Number(process.env.PORT) || 3005;

Bun.serve({
  port: PORT,
  fetch(req) {
    const url = new URL(req.url);

    if (url.pathname === "/health") {
      return Response.json({
        status: "ok",
        framework: "bun-native",
        pid: process.pid,
      });
    }

    if (url.pathname === "/scenarios") {
      const list = Object.entries(scenarios.scenarios).map(([key, val]) => ({
        key,
        name: val.name,
        description: val.description,
      }));
      return Response.json(list);
    }

    if (url.pathname === "/") {
      const scenarioName = url.searchParams.get("scenario") || "table100";
      const scenario = scenarios.scenarios[scenarioName as keyof typeof scenarios.scenarios];

      if (!scenario) {
        return new Response(`Unknown scenario: ${scenarioName}`, { status: 404 });
      }

      const Component = scenario.component;
      const html = ReactDOMServer.renderToString(React.createElement(Component));

      return new Response(
        `<!DOCTYPE html><html><head><title>Benchmark</title></head><body><div id="root">${html}</div></body></html>`,
        {
          headers: { "Content-Type": "text/html" },
        }
      );
    }

    return new Response("Not Found", { status: 404 });
  },
});

console.log(`[bun-native] Server listening on http://localhost:${PORT}`);
console.log(`[bun-native] PID: ${process.pid}`);

