#!/usr/bin/env node

/**
 * Comprehensive Benchmark Runner
 *
 * Features:
 * - Multi-framework comparison
 * - Multiple scenario support
 * - Statistical analysis (mean, median, p99, stddev)
 * - Warmup runs
 * - JSON and markdown output
 * - Progress reporting
 */

import { spawn, execSync } from "child_process";
import { writeFileSync, mkdirSync, existsSync } from "fs";
import { performance } from "perf_hooks";

// ============================================================================
// Configuration
// ============================================================================

const CONFIG = {
  // Number of warmup requests before measuring
  warmupRequests: 100,

  // Number of measurement requests
  measurementRequests: 1000,

  // Concurrent connections for wrk
  wrkConnections: 100,

  // Number of wrk threads
  wrkThreads: 4,

  // Duration for wrk test (seconds)
  wrkDuration: 10,

  // Delay between framework tests (ms)
  frameworkDelay: 2000,

  // Output directory
  outputDir: "./results",
};

const FRAMEWORKS = [
  { name: "dream-native", port: 3000, cmd: null }, // Manual start
  { name: "node-express", port: 3001, cmd: "npm run start:node-express", cwd: "./frameworks" },
  { name: "node-fastify", port: 3002, cmd: "npm run start:node-fastify", cwd: "./frameworks" },
  { name: "hono-node", port: 3003, cmd: "npm run start:hono-node", cwd: "./frameworks" },
  { name: "hono-bun", port: 3004, cmd: "bun run hono-bun/server.ts", cwd: "./frameworks" },
  { name: "bun-native", port: 3005, cmd: "bun run bun-native/server.tsx", cwd: "./frameworks" },
  { name: "preact", port: 3006, cmd: "npm run start:preact", cwd: "./frameworks" },
];

const SCENARIOS = [
  // Basic scenarios
  { key: "trivial", name: "Trivial", category: "basic" },
  { key: "shallow", name: "Shallow Tree", category: "basic" },

  // Depth tests
  { key: "deep10", name: "Deep 10", category: "depth" },
  { key: "deep25", name: "Deep 25", category: "depth" },
  { key: "deep50", name: "Deep 50", category: "depth" },

  // Width tests
  { key: "wide10", name: "Wide 10", category: "width" },
  { key: "wide100", name: "Wide 100", category: "width" },
  { key: "wide500", name: "Wide 500", category: "width" },

  // Table tests
  { key: "table10", name: "Table 10", category: "table" },
  { key: "table100", name: "Table 100", category: "table" },
  { key: "table500", name: "Table 500", category: "table" },
];

// ============================================================================
// Utilities
// ============================================================================

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const formatNumber = (num) => {
  if (num >= 1000000) return `${(num / 1000000).toFixed(2)}M`;
  if (num >= 1000) return `${(num / 1000).toFixed(2)}K`;
  return num.toFixed(2);
};

const formatLatency = (ms) => {
  if (ms < 1) return `${(ms * 1000).toFixed(2)}µs`;
  if (ms < 1000) return `${ms.toFixed(2)}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
};

const log = (msg) => console.log(`[${new Date().toISOString()}] ${msg}`);

// ============================================================================
// HTTP Testing
// ============================================================================

async function checkHealth(port) {
  try {
    const response = await fetch(`http://localhost:${port}/health`);
    return response.ok;
  } catch {
    return false;
  }
}

async function waitForServer(port, maxAttempts = 30) {
  for (let i = 0; i < maxAttempts; i++) {
    if (await checkHealth(port)) {
      return true;
    }
    await sleep(500);
  }
  return false;
}

async function warmup(port, scenario, count) {
  const url = `http://localhost:${port}/?scenario=${scenario}`;
  const promises = [];

  for (let i = 0; i < count; i++) {
    promises.push(fetch(url).catch(() => null));
    if (promises.length >= 10) {
      await Promise.all(promises);
      promises.length = 0;
    }
  }

  if (promises.length > 0) {
    await Promise.all(promises);
  }
}

function parseWrkOutput(output) {
  const result = {
    requests: 0,
    requestsPerSec: 0,
    latencyAvg: 0,
    latencyStdev: 0,
    latencyMax: 0,
    latencyP50: 0,
    latencyP75: 0,
    latencyP90: 0,
    latencyP99: 0,
    transferPerSec: 0,
    errors: 0,
  };

  // Parse requests
  const reqMatch = output.match(/(\d+)\s+requests\s+in/);
  if (reqMatch) result.requests = parseInt(reqMatch[1], 10);

  // Parse requests/sec
  const rpsMatch = output.match(/Requests\/sec:\s+([\d.]+)/);
  if (rpsMatch) result.requestsPerSec = parseFloat(rpsMatch[1]);

  // Parse latency stats
  const latencyMatch = output.match(/Latency\s+([\d.]+)(us|ms|s)\s+([\d.]+)(us|ms|s)\s+([\d.]+)(us|ms|s)/);
  if (latencyMatch) {
    const parseTime = (val, unit) => {
      const num = parseFloat(val);
      if (unit === "us") return num / 1000;
      if (unit === "s") return num * 1000;
      return num;
    };
    result.latencyAvg = parseTime(latencyMatch[1], latencyMatch[2]);
    result.latencyStdev = parseTime(latencyMatch[3], latencyMatch[4]);
    result.latencyMax = parseTime(latencyMatch[5], latencyMatch[6]);
  }

  // Parse transfer rate
  const transferMatch = output.match(/Transfer\/sec:\s+([\d.]+)(\w+)/);
  if (transferMatch) {
    let val = parseFloat(transferMatch[1]);
    const unit = transferMatch[2];
    if (unit === "KB") val *= 1024;
    if (unit === "MB") val *= 1024 * 1024;
    if (unit === "GB") val *= 1024 * 1024 * 1024;
    result.transferPerSec = val;
  }

  // Parse errors
  const errorMatch = output.match(/Socket errors:.*?(\d+)\s+connect.*?(\d+)\s+read.*?(\d+)\s+write.*?(\d+)\s+timeout/);
  if (errorMatch) {
    result.errors = parseInt(errorMatch[1], 10) + parseInt(errorMatch[2], 10) +
                    parseInt(errorMatch[3], 10) + parseInt(errorMatch[4], 10);
  }

  return result;
}

async function runWrk(port, scenario, duration, connections, threads) {
  const url = `http://localhost:${port}/?scenario=${scenario}`;
  const cmd = `wrk -t${threads} -c${connections} -d${duration}s --latency ${url}`;

  try {
    const output = execSync(cmd, { encoding: "utf-8", timeout: (duration + 10) * 1000 });
    return parseWrkOutput(output);
  } catch (error) {
    log(`wrk error: ${error.message}`);
    return null;
  }
}

// ============================================================================
// Simple HTTP benchmark (no wrk dependency)
// ============================================================================

async function runSimpleBenchmark(port, scenario, requests, concurrency) {
  const url = `http://localhost:${port}/?scenario=${scenario}`;
  const latencies = [];
  let errors = 0;
  let totalBytes = 0;

  const runRequest = async () => {
    const start = performance.now();
    try {
      const response = await fetch(url);
      const text = await response.text();
      const end = performance.now();
      latencies.push(end - start);
      totalBytes += text.length;
    } catch {
      errors++;
    }
  };

  const startTime = performance.now();

  // Run in batches for concurrency
  for (let i = 0; i < requests; i += concurrency) {
    const batch = Math.min(concurrency, requests - i);
    await Promise.all(Array(batch).fill().map(runRequest));
  }

  const totalTime = (performance.now() - startTime) / 1000; // seconds

  latencies.sort((a, b) => a - b);

  const sum = latencies.reduce((a, b) => a + b, 0);
  const avg = sum / latencies.length;
  const variance = latencies.reduce((a, b) => a + Math.pow(b - avg, 2), 0) / latencies.length;

  return {
    requests: latencies.length,
    requestsPerSec: latencies.length / totalTime,
    latencyAvg: avg,
    latencyStdev: Math.sqrt(variance),
    latencyMax: latencies[latencies.length - 1],
    latencyP50: latencies[Math.floor(latencies.length * 0.5)],
    latencyP75: latencies[Math.floor(latencies.length * 0.75)],
    latencyP90: latencies[Math.floor(latencies.length * 0.9)],
    latencyP99: latencies[Math.floor(latencies.length * 0.99)],
    transferPerSec: totalBytes / totalTime,
    errors,
  };
}

// ============================================================================
// Process Management
// ============================================================================

const processes = new Map();

function startFramework(framework) {
  if (!framework.cmd) return null;

  log(`Starting ${framework.name}...`);

  const [cmd, ...args] = framework.cmd.split(" ");
  const proc = spawn(cmd, args, {
    cwd: framework.cwd,
    stdio: "pipe",
    detached: false,
    env: { ...process.env, PORT: String(framework.port) },
  });

  proc.stdout?.on("data", (data) => {
    if (process.env.VERBOSE) {
      console.log(`[${framework.name}] ${data.toString().trim()}`);
    }
  });

  proc.stderr?.on("data", (data) => {
    if (process.env.VERBOSE) {
      console.error(`[${framework.name}] ${data.toString().trim()}`);
    }
  });

  processes.set(framework.name, proc);
  return proc;
}

function stopFramework(framework) {
  const proc = processes.get(framework.name);
  if (proc) {
    proc.kill("SIGTERM");
    processes.delete(framework.name);
  }
}

function cleanup() {
  log("Cleaning up...");
  for (const [name, proc] of processes) {
    log(`Stopping ${name}...`);
    proc.kill("SIGTERM");
  }
  processes.clear();
}

// ============================================================================
// Main Runner
// ============================================================================

async function runBenchmark(options = {}) {
  const {
    frameworks = FRAMEWORKS,
    scenarios = SCENARIOS,
    useWrk = true,
    outputFormat = "all",
  } = options;

  const results = {
    timestamp: new Date().toISOString(),
    config: CONFIG,
    frameworks: [],
  };

  // Ensure output directory exists
  if (!existsSync(CONFIG.outputDir)) {
    mkdirSync(CONFIG.outputDir, { recursive: true });
  }

  log("=".repeat(60));
  log("Server Reason React Benchmark Suite");
  log("=".repeat(60));

  // Check for wrk
  let hasWrk = false;
  try {
    execSync("which wrk", { encoding: "utf-8" });
    hasWrk = true;
    log("Using wrk for load testing");
  } catch {
    log("wrk not found, using simple HTTP benchmark");
  }

  for (const framework of frameworks) {
    log(`\n${"─".repeat(50)}`);
    log(`Framework: ${framework.name}`);
    log(`${"─".repeat(50)}`);

    const frameworkResult = {
      name: framework.name,
      port: framework.port,
      scenarios: [],
    };

    // Start framework if needed
    if (framework.cmd) {
      startFramework(framework);
      await sleep(2000);
    }

    // Wait for server
    const ready = await waitForServer(framework.port);
    if (!ready) {
      log(`❌ ${framework.name} failed to start`);
      stopFramework(framework);
      continue;
    }
    log(`✓ ${framework.name} ready on port ${framework.port}`);

    for (const scenario of scenarios) {
      process.stdout.write(`  ${scenario.name.padEnd(20)}`);

      // Warmup
      await warmup(framework.port, scenario.key, CONFIG.warmupRequests);

      // Run benchmark
      let result;
      if (useWrk && hasWrk) {
        result = await runWrk(
          framework.port,
          scenario.key,
          CONFIG.wrkDuration,
          CONFIG.wrkConnections,
          CONFIG.wrkThreads
        );
      } else {
        result = await runSimpleBenchmark(
          framework.port,
          scenario.key,
          CONFIG.measurementRequests,
          50
        );
      }

      if (result) {
        console.log(
          `${formatNumber(result.requestsPerSec).padStart(10)} req/s  ` +
          `${formatLatency(result.latencyAvg).padStart(10)} avg  ` +
          `${formatLatency(result.latencyP99 || result.latencyMax).padStart(10)} p99`
        );

        frameworkResult.scenarios.push({
          ...scenario,
          ...result,
        });
      } else {
        console.log("  ❌ Failed");
      }
    }

    results.frameworks.push(frameworkResult);

    // Stop framework
    stopFramework(framework);
    await sleep(CONFIG.frameworkDelay);
  }

  // Write results
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");

  if (outputFormat === "all" || outputFormat === "json") {
    const jsonPath = `${CONFIG.outputDir}/benchmark-${timestamp}.json`;
    writeFileSync(jsonPath, JSON.stringify(results, null, 2));
    log(`\nResults saved to: ${jsonPath}`);
  }

  if (outputFormat === "all" || outputFormat === "markdown") {
    const markdown = generateMarkdown(results);
    const mdPath = `${CONFIG.outputDir}/benchmark-${timestamp}.md`;
    writeFileSync(mdPath, markdown);
    log(`Markdown report: ${mdPath}`);
  }

  return results;
}

// ============================================================================
// Report Generation
// ============================================================================

function generateMarkdown(results) {
  const lines = [
    "# Benchmark Results",
    "",
    `Generated: ${results.timestamp}`,
    "",
    "## Configuration",
    "",
    "| Setting | Value |",
    "| --- | --- |",
    `| Warmup Requests | ${results.config.warmupRequests} |`,
    `| Measurement Duration | ${results.config.wrkDuration}s |`,
    `| Connections | ${results.config.wrkConnections} |`,
    `| Threads | ${results.config.wrkThreads} |`,
    "",
    "## Results",
    "",
  ];

  // Group by scenario
  const scenarioResults = new Map();

  for (const framework of results.frameworks) {
    for (const scenario of framework.scenarios) {
      if (!scenarioResults.has(scenario.key)) {
        scenarioResults.set(scenario.key, {
          name: scenario.name,
          results: [],
        });
      }
      scenarioResults.get(scenario.key).results.push({
        framework: framework.name,
        ...scenario,
      });
    }
  }

  for (const [key, data] of scenarioResults) {
    lines.push(`### ${data.name}`);
    lines.push("");
    lines.push("| Framework | Requests/sec | Avg Latency | P99 Latency | Errors |");
    lines.push("| --- | ---: | ---: | ---: | ---: |");

    // Sort by requests/sec
    data.results.sort((a, b) => b.requestsPerSec - a.requestsPerSec);

    for (const r of data.results) {
      lines.push(
        `| ${r.framework} | ${formatNumber(r.requestsPerSec)} | ` +
        `${formatLatency(r.latencyAvg)} | ${formatLatency(r.latencyP99 || r.latencyMax)} | ${r.errors} |`
      );
    }
    lines.push("");
  }

  // Summary table
  lines.push("## Summary (Table 100 Scenario)");
  lines.push("");

  const table100Results = results.frameworks
    .map((f) => {
      const scenario = f.scenarios.find((s) => s.key === "table100");
      return scenario ? { framework: f.name, ...scenario } : null;
    })
    .filter(Boolean)
    .sort((a, b) => b.requestsPerSec - a.requestsPerSec);

  if (table100Results.length > 0) {
    const fastest = table100Results[0].requestsPerSec;

    lines.push("| Rank | Framework | Requests/sec | Relative |");
    lines.push("| ---: | --- | ---: | ---: |");

    table100Results.forEach((r, i) => {
      const relative = ((r.requestsPerSec / fastest) * 100).toFixed(1);
      lines.push(`| ${i + 1} | ${r.framework} | ${formatNumber(r.requestsPerSec)} | ${relative}% |`);
    });
  }

  return lines.join("\n");
}

// ============================================================================
// CLI
// ============================================================================

process.on("SIGINT", () => {
  cleanup();
  process.exit(0);
});

process.on("SIGTERM", () => {
  cleanup();
  process.exit(0);
});

const args = process.argv.slice(2);

if (args.includes("--help") || args.includes("-h")) {
  console.log(`
Server Reason React Benchmark Runner

Usage:
  node runner.mjs [options]

Options:
  --frameworks <list>   Comma-separated list of frameworks to test
  --scenarios <list>    Comma-separated list of scenarios to run
  --simple              Use simple HTTP benchmark instead of wrk
  --verbose             Show framework output
  --help, -h            Show this help

Examples:
  node runner.mjs
  node runner.mjs --frameworks dream-native,node-express
  node runner.mjs --scenarios trivial,table100
  VERBOSE=1 node runner.mjs
  `);
  process.exit(0);
}

// Parse arguments
const parseList = (flag) => {
  const idx = args.indexOf(flag);
  if (idx !== -1 && args[idx + 1]) {
    return args[idx + 1].split(",");
  }
  return null;
};

const frameworkFilter = parseList("--frameworks");
const scenarioFilter = parseList("--scenarios");
const useWrk = !args.includes("--simple");

const filteredFrameworks = frameworkFilter
  ? FRAMEWORKS.filter((f) => frameworkFilter.includes(f.name))
  : FRAMEWORKS;

const filteredScenarios = scenarioFilter
  ? SCENARIOS.filter((s) => scenarioFilter.includes(s.key))
  : SCENARIOS;

runBenchmark({
  frameworks: filteredFrameworks,
  scenarios: filteredScenarios,
  useWrk,
}).then(() => {
  cleanup();
  process.exit(0);
}).catch((err) => {
  console.error(err);
  cleanup();
  process.exit(1);
});

