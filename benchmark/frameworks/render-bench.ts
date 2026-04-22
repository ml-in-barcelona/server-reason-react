/**
 * Pure Render Benchmark - No HTTP
 * Comparable to streaming_bench.ml
 */

if (process.env.NODE_ENV !== "production") {
  console.error(
    "[render-bench] ERROR: NODE_ENV is not 'production' (got " +
    JSON.stringify(process.env.NODE_ENV) +
    ").\n" +
    "React's development build is slower than production. Re-run with:\n" +
    "  NODE_ENV=production bun render-bench.ts\n" +
    "  NODE_ENV=production node render-bench-node.mjs\n"
  );
  process.exit(1);
}

import React from "react";
import ReactDOMServer from "react-dom/server";
import * as scenarios from "./shared/scenarios.jsx";

const ITERATIONS = 100;

function measureTimeUs(fn: () => string): [string, number] {
  const start = performance.now();
  const result = fn();
  const end = performance.now();
  return [result, (end - start) * 1000]; // Convert ms to µs
}

function formatTimeUs(us: number): string {
  if (us < 1000) return `${us.toFixed(2)}µs`;
  if (us < 1_000_000) return `${(us / 1000).toFixed(2)}ms`;
  return `${(us / 1_000_000).toFixed(2)}s`;
}

interface Result {
  name: string;
  avgTimeUs: number;
  outputBytes: number;
  throughputMbS: number;
}

function benchmark(name: string, component: React.ComponentType): Result {
  let totalTime = 0;
  let outputBytes = 0;

  for (let i = 0; i < ITERATIONS; i++) {
    const [html, timeUs] = measureTimeUs(() =>
      ReactDOMServer.renderToString(React.createElement(component))
    );
    totalTime += timeUs;
    outputBytes = html.length;
  }

  const avgTime = totalTime / ITERATIONS;
  const throughput = (outputBytes / 1_000_000) / (avgTime / 1_000_000);

  return {
    name,
    avgTimeUs: avgTime,
    outputBytes,
    throughputMbS: throughput,
  };
}

const runtime =
  typeof (globalThis as any).Bun !== "undefined"
    ? `Bun ${(globalThis as any).Bun.version}`
    : `Node ${process.versions.node}`;

console.log(`Pure Render Benchmark (${runtime} + React, NODE_ENV=production)`);
console.log(`Iterations per scenario: ${ITERATIONS}\n`);

// Keep this list in sync with benchmark/streaming/streaming_bench.ml so each
const testScenarios = [
  "trivial",
  "shallow",
  "deep10",
  "deep50",
  "wide10",
  "wide100",
  "wide500",
  "table10",
  "table100",
  "table500",
  "propsSmall",
  "propsMedium",
  "ecommerce24",
  "ecommerce48",
  "dashboard",
  "blog50",
  "form",
];

const results: Result[] = [];

for (const key of testScenarios) {
  const scenario = scenarios.scenarios[key as keyof typeof scenarios.scenarios];
  if (scenario) {
    const result = benchmark(key, scenario.component);
    results.push(result);
    console.log(`${key}: ${formatTimeUs(result.avgTimeUs)} (${result.outputBytes}B)`);
  }
}

console.log("\n" + "=".repeat(70));
console.log("COMPARISON TABLE");
console.log("=".repeat(70));
console.log(`${"Scenario".padEnd(20)} ${"Time".padStart(12)} ${"Size".padStart(10)} ${"Throughput".padStart(12)}`);
console.log("-".repeat(70));

for (const r of results) {
  console.log(
    `${r.name.padEnd(20)} ${formatTimeUs(r.avgTimeUs).padStart(12)} ${(r.outputBytes + "B").padStart(10)} ${(r.throughputMbS.toFixed(1) + "MB/s").padStart(12)}`
  );
}
console.log("=".repeat(70));
