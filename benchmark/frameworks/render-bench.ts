/**
 * Pure Render Benchmark - No HTTP
 * Comparable to streaming_bench.ml
 */

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

console.log("Pure Render Benchmark (Bun + React)");
console.log(`Iterations per scenario: ${ITERATIONS}\n`);

const testScenarios = [
  "trivial",
  "shallow",
  "deep10",
  "deep50",
  "wide10",
  "wide100",
  "table10",
  "table100",
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
