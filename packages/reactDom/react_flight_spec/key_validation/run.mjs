import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createServer } from "node:http";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";
import { chromium } from "playwright";

const here = path.dirname(fileURLToPath(import.meta.url));
const spec = path.dirname(here);
const root = path.resolve(spec, "../../..");
const artifacts = path.join(root, "_build/flight-key-validation");
const controlsOnly = process.argv.includes("--controls-only");
const filter = process.env.FLIGHT_KEY_CASE;
const missingKey = /Each child in a list should have a unique ["']key["'] prop/;
const duplicateKey = /Encountered two children with the same key/;
await mkdir(artifacts, { recursive: true });

const native = controlsOnly ? [] : JSON.parse(execFileSync(
  path.join(root, "_build/default/packages/reactDom/react_flight_spec/key_validation/export_fixtures.exe"),
  { encoding: "utf8", maxBuffer: 16 * 1024 * 1024, timeout: 30_000 },
));
if (!controlsOnly) await writeFile(path.join(artifacts, "native.json"), JSON.stringify(native, null, 2));

function checkTuples(value, env, tuples) {
  if (Array.isArray(value)) {
    if (value[0] === "$") {
      assert.equal(value.length, 7, "Native element tuple must have seven fields");
      assert.ok([0, 1, 2].includes(value[6]), "Native validation must be 0, 1, or 2");
      if (env !== "Dev") assert.deepEqual(value.slice(4, 6), [null, null]);
      tuples.push(value);
    }
    value.forEach((item) => checkTuples(item, env, tuples));
  } else if (value && typeof value === "object") {
    Object.values(value).forEach((item) => checkTuples(item, env, tuples));
  }
}

const wireFailures = [];
for (const fixture of native.filter((fixture) => !fixture.hydration)) {
  try {
    const tuples = [];
    for (const row of fixture.chunks.join("").trimEnd().split("\n")) {
      const payload = row.slice(row.indexOf(":") + 1);
      if (payload.startsWith("[") || payload.startsWith("{")) checkTuples(JSON.parse(payload), fixture.env, tuples);
    }
    const expectedSpanStates = {
      "static-host": [1, 1],
      "unkeyed-list": [2, 2],
      "unkeyed-array": [2, 2],
      "singleton-list": [2],
      "singleton-array": [2],
      "keyed-list": [0, 0],
      "keyed-array": [0, 0],
      "extracted-static": [1],
      "cloned-static": [1],
    }[fixture.name];
    if (expectedSpanStates) {
      assert.deepEqual(tuples.filter((tuple) => tuple[1] === "span").map((tuple) => tuple[6]), expectedSpanStates);
    }
    if (fixture.name === "static-host") assert.equal(tuples[0][6], 0, "Bare root validation");
    if (fixture.name === "server-error-redaction") {
      assert.equal(fixture.chunks.join("").includes("private-key-validation-error"), fixture.env === "Dev");
    }
    if (fixture.pending) assert.ok(fixture.initialChunks < fixture.chunks.length, "Pending fixture needs late rows");
  } catch (error) {
    wireFailures.push({ name: `${fixture.env}/${fixture.name}`, error: error.message });
  }
}

const bundles = new Map();
for (const environment of ["development", "production"]) {
  const result = await build({
    entryPoints: [path.join(here, "browser.mjs")],
    bundle: true,
    write: false,
    format: "iife",
    platform: "browser",
    define: { "process.env.NODE_ENV": JSON.stringify(environment) },
    alias: {
      react: path.join(spec, "node_modules/react"),
      "react-dom": path.join(spec, "node_modules/react-dom"),
      "@pedrobslisboa/react-client": path.join(spec, "node_modules/@pedrobslisboa/react-client"),
    },
    metafile: true,
  });
  const reactRoots = new Set(Object.keys(result.metafile.inputs)
    .filter((name) => /[/\\]react[/\\](?:cjs[/\\]|index\.js)/.test(name))
    .map((name) => path.resolve(name).split(`${path.sep}react${path.sep}`)[0]));
  assert.equal(reactRoots.size, 1, `Exactly one React copy in ${environment}`);
  const reactPackage = JSON.parse(await readFile(path.join(spec, "node_modules/react/package.json"), "utf8"));
  assert.equal(reactPackage.version, "19.1.0");
  for (const dependency of ["react-dom", "@pedrobslisboa/react-client"]) {
    assert.equal(JSON.parse(await readFile(path.join(spec, "node_modules", dependency, "package.json"), "utf8")).version, "19.1.0");
  }
  bundles.set(environment, result.outputFiles[0].text);
  await writeFile(path.join(artifacts, `${environment}.js`), result.outputFiles[0].text);
  await writeFile(path.join(artifacts, `${environment}.meta.json`), JSON.stringify(result.metafile, null, 2));
  console.log(`${environment}: one React 19.1.0 copy; shipped Flight adapter bundled`);
}

function control(name, state, missing) {
  const child = (text) => state === undefined
    ? ["$", "span", null, { children: text }]
    : ["$", "span", null, { children: text }, null, null, state];
  const row = `0:${JSON.stringify(["$", "div", null, { children: [child("a"), child("b")] }, null, null, 0])}\n`;
  return { name, env: "control", chunks: [row], initialChunks: 1, text: "ab", missing };
}

const controls = [
  { name: "plain-react-unkeyed", env: "control", plain: true, text: "ab", missing: true },
  control("legacy-four-field-static", undefined, true),
  control("unvalidated-zero", 0, true),
  control("hardcoded-one-hides-missing-key", 1, false),
  control("missing-key-two", 2, true),
  { name: "invalid-json", env: "control", chunks: ["0:{invalid\n"], initialChunks: 1, error: "decode" },
  { name: "invalid-element-type", env: "control", chunks: ['0:["$",{},null,{},null,null,0]\n'], initialChunks: 1, error: "render" },
];

const waiting = new Map();
const server = createServer((request, response) => {
  const [, environment, id, resource] = new URL(request.url, "http://localhost").pathname.split("/");
  if (resource === "browser.js") {
    response.writeHead(200, { "Content-Type": "text/javascript" });
    response.end(bundles.get(environment));
  } else if (resource === "release") {
    const finish = waiting.get(id);
    if (!finish) {
      response.writeHead(409);
      response.end("No pending HTML response");
      return;
    }
    waiting.delete(id);
    finish();
    response.end("released");
  } else if (resource === "index.html") {
    const fixture = native[Number(id)];
    response.writeHead(200, { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" });
    if (fixture?.hydration) {
      response.write(fixture.shell);
      for (const chunk of fixture.chunks.slice(0, fixture.initialChunks)) response.write(chunk);
      waiting.set(id, () => {
        for (const chunk of fixture.chunks.slice(fixture.initialChunks)) response.write(chunk);
        response.end();
      });
      response.on("close", () => waiting.delete(id));
    } else {
      response.end('<!doctype html><html><head></head><body><div id="result"></div><script src="./browser.js"></script></body></html>');
    }
  } else {
    response.writeHead(404);
    response.end();
  }
});
async function listen() {
  for (let port = 25000; port <= 25099; port++) {
    try {
      await new Promise((resolve, reject) => {
        server.once("error", reject);
        server.listen(port, "0.0.0.0", () => {
          server.removeListener("error", reject);
          resolve();
        });
      });
      return;
    } catch (error) {
      if (error.code !== "EADDRINUSE") throw error;
    }
  }
  throw new Error("No free browser test port in 25000–25099");
}
await listen();
const origin = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch();
const results = [];

async function runCase(environment, fixture) {
  const page = await browser.newPage();
  page.setDefaultTimeout(10_000);
  const pageErrors = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  const id = fixture.env === "control" ? "control" : String(native.indexOf(fixture));
  const url = `${origin}/${environment}/${id}/index.html`;
  const label = `${environment}/${fixture.env}/${fixture.name}`;
  let observed;
  try {
    await page.goto(url, { waitUntil: "commit" });
    await page.waitForFunction(() => typeof window.startFlightTest === "function");
    if (!fixture.hydration) await page.evaluate((data) => window.startFlightTest(data), fixture);
    await page.waitForFunction(() => window.flightTest.started);
    if (fixture.pending) {
      await page.locator("#pending").waitFor({ state: "visible" });
      assert.equal(await page.evaluate(() => window.flightTest.streamClosed), false);
    }
    if (fixture.hydration) {
      const released = await page.request.post(`${origin}/${environment}/${id}/release`);
      assert.equal(released.status(), 200);
    } else if (!fixture.plain) {
      await page.evaluate(() => window.releaseFlightTest());
    }
    if (fixture.error) {
      await page.waitForFunction(() => window.flightTest.renderErrors.length > 0);
    } else {
      await page.waitForFunction((text) =>
        window.flightTest.renderErrors.length > 0 ||
        (document.getElementById("result")?.textContent === text &&
        window.flightTest.streamClosed && window.flightTest.commits > 0),
      fixture.text);
      assert.deepEqual(await page.evaluate(() => window.flightTest.renderErrors), [], "React rendering errors");
      if (fixture.text.includes("count:0")) {
        await page.waitForFunction(() => window.flightTest.clientCommits > 0);
        assert.equal(await page.evaluate(() => window.flightTest.moduleLoads), 1);
        await page.getByRole("button", { name: "count:0" }).click();
        await page.getByRole("button", { name: "count:1" }).waitFor();
      }
      if (fixture.document) {
        assert.equal(await page.title(), "Flight key validation");
        assert.equal(await page.locator("html").count(), 1);
        assert.equal(await page.locator("body").count(), 1);
      }
    }
    await page.evaluate(() => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    observed = await page.evaluate(() => window.flightTest);
    assert.equal(observed.version, "19.1.0");
    assert.deepEqual(pageErrors, [], "Uncaught browser errors");
    assert.deepEqual(observed.recoverableErrors, [], "Hydration/recoverable errors");
    if (fixture.error === "decode") assert.ok(observed.decodeErrors.length > 0, "Decode control must fail in decoding");
    else assert.deepEqual(observed.decodeErrors, [], "Flight decoding errors");
    if (fixture.error) assert.ok(observed.renderErrors.length > 0, "Negative control must reach error handler");
    else assert.deepEqual(observed.renderErrors, [], "React rendering errors");
    if (!fixture.error) {
      const missing = observed.console.filter(({ text }) => missingKey.test(text));
      const duplicate = observed.console.filter(({ text }) => duplicateKey.test(text));
      const unexpected = observed.console.filter(({ text }) => !missingKey.test(text) && !duplicateKey.test(text));
      assert.deepEqual(unexpected, [], "Unexpected browser diagnostics");
      assert.equal(missing.length > 0, environment === "development" && !!fixture.missing, "Missing-key warning category");
      assert.equal(duplicate.length > 0, environment === "development" && !!fixture.duplicate, "Duplicate-key warning category");
    }
    results.push({ name: label, passed: true, observed });
    console.log(`PASS ${label}`);
  } catch (error) {
    observed ??= await page.evaluate(() => window.flightTest).catch(() => null);
    const dom = await page.locator("#result").textContent().catch(() => null);
    results.push({ name: label, passed: false, error: error.message, pageErrors, observed, dom });
    console.error(`FAIL ${label}: ${error.message}`);
  } finally {
    await page.close();
  }
}

try {
  for (const environment of ["development", "production"]) {
    for (const fixture of [...controls, ...native]) {
      // React's production decoder rejects debug rows (error 504).
      if (environment === "production" && fixture.debug) continue;
      if (!filter || fixture.name.includes(filter)) await runCase(environment, fixture);
    }
  }
} finally {
  await browser.close();
  server.closeAllConnections();
  await new Promise((resolve) => server.close(resolve));
  await writeFile(path.join(artifacts, controlsOnly ? "controls-results.json" : "results.json"), JSON.stringify({ wireFailures, results }, null, 2));
}

const failures = results.filter((result) => !result.passed);
console.log(`${results.length - failures.length}/${results.length} browser cases passed; ${wireFailures.length} wire failures. Artifacts: ${artifacts}`);
if (results.length === 0 || failures.length || wireFailures.length) process.exitCode = 1;
