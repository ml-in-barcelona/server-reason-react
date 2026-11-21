import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { chmod, copyFile, mkdir, mkdtemp, readdir, symlink } from "node:fs/promises";
import { existsSync } from "node:fs";
import { createServer } from "node:net";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../../../..");
const buildDir = path.resolve(root, process.env.ROUTER_E2E_BUILD_DIR ?? "_build");
const serverExe = path.join(buildDir, "default/demo/server/server.exe");
const only = process.env.ROUTER_E2E_ONLY;

async function chromiumPath() {
  if (process.env.ROUTER_E2E_CHROMIUM) return process.env.ROUTER_E2E_CHROMIUM;
  const bundled = chromium.executablePath();
  if (existsSync(bundled)) return bundled;
  const cache = path.join(os.homedir(), ".cache/ms-playwright");
  const revisions = (await readdir(cache).catch(() => []))
    .filter((name) => /^chromium-\d+$/.test(name))
    .sort((a, b) => Number(b.split("-")[1]) - Number(a.split("-")[1]));
  for (const revision of revisions) {
    const candidate = path.join(cache, revision, "chrome-linux64/chrome");
    if (existsSync(candidate)) return candidate;
  }
  throw new Error("no Chromium found: run `npx playwright install chromium` or set ROUTER_E2E_CHROMIUM");
}

function freePort() {
  return new Promise((resolve, reject) => {
    const server = createServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      server.close(() => resolve(port));
    });
  });
}

async function startServer() {
  if (!existsSync(serverExe)) throw new Error(`missing ${serverExe}: build the demo first`);
  const runDir = await mkdtemp(path.join(os.tmpdir(), "router-e2e-"));
  await mkdir(path.join(runDir, "demo/server/db"), { recursive: true });
  await copyFile(path.join(root, "demo/server/db/notes.json"), path.join(runDir, "demo/server/db/notes.json"));
  const demoBuild = path.join(runDir, "_build/default/demo");
  await mkdir(path.join(demoBuild, "server"), { recursive: true });
  await mkdir(path.join(demoBuild, "client"), { recursive: true });
  const runExe = path.join(demoBuild, "server/server.exe");
  await copyFile(serverExe, runExe);
  await chmod(runExe, 0o755);
  await symlink(path.join(buildDir, "default/demo/output.css"), path.join(demoBuild, "output.css"));
  await symlink(path.join(buildDir, "default/demo/client/dist"), path.join(demoBuild, "client/dist"));
  const port = await freePort();
  const child = spawn(runExe, [], {
    cwd: runDir,
    env: { ...process.env, PORT: String(port), SERVER_INTERFACE: "127.0.0.1" },
    stdio: ["ignore", "pipe", "pipe"],
  });
  let log = "";
  child.stdout.on("data", (chunk) => (log += chunk));
  child.stderr.on("data", (chunk) => (log += chunk));
  const origin = `http://127.0.0.1:${port}`;
  for (let attempt = 0; attempt < 100; attempt++) {
    try {
      await fetch(`${origin}/demo/router`);
      return { origin, stop: () => child.kill(), log: () => log };
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  child.kill();
  throw new Error(`the demo server did not start:\n${log}`);
}

function watch(page) {
  const requests = [];
  const console = [];
  page.on("request", (request) => {
    const headers = request.headers();
    requests.push({
      url: new URL(request.url()).pathname + new URL(request.url()).search,
      document: request.resourceType() === "document",
      rsc: (headers.accept ?? "").includes("application/react.component"),
      prefetch: headers["router-prefetch"] ?? null,
    });
  });
  const failed = [];
  page.on("response", (response) => {
    if (response.status() >= 400) failed.push(`${response.status()} ${new URL(response.url()).pathname}`);
  });
  page.on("console", (message) => {
    if (message.type() === "error" || message.type() === "warning") console.push(message.text());
  });
  return {
    requests,
    failed,
    console,
    since(mark) {
      return requests.slice(mark);
    },
    mark() {
      return requests.length;
    },
  };
}

async function ready(page, selector) {
  await page.waitForFunction(
    (selector) => {
      const element = document.querySelector(selector);
      return (
        element &&
        Object.keys(element).some((key) => key.startsWith("__reactFiber")) &&
        document.querySelector("[data-router-announcer]") !== null
      );
    },
    selector,
    { timeout: 15_000 },
  );
}

const reactConsole = (net) => net.console.filter((text) => !text.startsWith("Failed to load resource"));
const absenceWindow = (page) => page.waitForTimeout(500);
const scrollY = (page) => page.evaluate(() => window.scrollY);
const navigations = (requests, url) => requests.filter((r) => r.url === url && r.rsc && !r.prefetch);
const pathOf = (page) => new URL(page.url()).pathname;

async function scrollTo(page, y) {
  await page.evaluate((y) => window.scrollTo(0, y), y);
  await page.waitForFunction((y) => Math.round(window.scrollY) === y, y);
}

async function waitForScroll(page, y) {
  await page
    .waitForFunction((y) => Math.round(window.scrollY) === y, y, { timeout: 5_000 })
    .catch(() => null);
  return Math.round(await scrollY(page));
}

function prefetchOf(page, path, level) {
  return page.waitForResponse(
    (response) =>
      new URL(response.url()).pathname === path && response.request().headers()["router-prefetch"] === level,
  );
}

const checks = [];
const check = (name, run) => checks.push({ name, run });

check("link click navigates without a document request", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router`);
  await ready(page, 'a[href="/demo/router/1"]');
  const mark = net.mark();
  await page.click('a[href="/demo/router/1"]');
  await page.waitForURL(`${origin}/demo/router/1`);
  await page.waitForFunction(() => document.querySelector("main")?.innerText.includes("Our markdown parser is poor"));
  const after = net.since(mark);
  assert.equal(after.filter((r) => r.document).length, 0, "a document request was made");
  assert.equal(navigations(after, "/demo/router/1").length, 1, "expected one navigation request");
  return `navigation requests: ${navigations(after, "/demo/router/1").length}, documents: 0`;
});

check("a render error after a client navigation shows the error boundary", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".link-crash");
  await page.click(".link-crash");
  await page.waitForURL(`${origin}/demo/router/e2e/crash`);
  await page.waitForFunction(() =>
    document.querySelector("main")?.innerText.includes("The requested note could not be loaded."),
  );
  assert.ok(await page.$(".layout-long"), "the layout around the boundary is gone");
  await page.click(".layout-long");
  await page.waitForSelector("#e2e-long");
  assert.equal(pathOf(page), "/demo/router/e2e/long");
  return "boundary shown inside the layout, next navigation renders the page";
});

check("plain anchor to a route is intercepted", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#plain-route");
  const mark = net.mark();
  await page.click("#plain-route");
  await page.waitForSelector("#e2e-long");
  const after = net.since(mark);
  assert.equal(after.filter((r) => r.document).length, 0, "a document request was made");
  assert.equal(pathOf(page), "/demo/router/e2e/long");
  return `navigation requests: ${navigations(after, "/demo/router/e2e/long").length}, documents: 0`;
});

check("plain anchor to a URL without a route loads in full at once", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#plain-missing");
  const mark = net.mark();
  const response = page.waitForResponse((r) => new URL(r.url()).pathname === "/demo/router/e2e/missing.txt");
  await page.click("#plain-missing");
  await response;
  await page.waitForURL(`${origin}/demo/router/e2e/missing.txt`);
  const toMissing = net.since(mark).filter((r) => r.url === "/demo/router/e2e/missing.txt");
  assert.deepEqual(
    toMissing.map((r) => (r.document ? "document" : r.rsc ? "rsc" : "other")),
    ["document"],
    "expected exactly one document request",
  );
  return "requests to missing.txt: [document]";
});

check("scroll restores on Back and Forward", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e/long`);
  await ready(page, ".long-back");
  await scrollTo(page, 1500);
  await page.evaluate(() => document.querySelector(".long-back").click());
  await page.waitForSelector("#e2e-page");
  const onChecks = await waitForScroll(page, 0);
  await scrollTo(page, 700);
  await page.goBack();
  await page.waitForSelector("#e2e-long");
  const back = await waitForScroll(page, 1500);
  await page.goForward();
  await page.waitForSelector("#e2e-page");
  const forward = await waitForScroll(page, 700);
  assert.equal(onChecks, 0, "a new page did not start at the top");
  assert.equal(back, 1500, "Back did not restore the scroll position");
  assert.equal(forward, 700, "Forward did not restore the scroll position");
  return `new page ${onChecks}, Back ${back}, Forward ${forward}`;
});

check("scroll restores on Back after a reload", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e/long`);
  await ready(page, ".long-back");
  await scrollTo(page, 1200);
  await page.evaluate(() => document.querySelector(".long-back").click());
  await page.waitForSelector("#e2e-page");
  await page.reload();
  await ready(page, "#plain-route");
  await page.goBack();
  await page.waitForSelector("#e2e-long");
  const back = await waitForScroll(page, 1200);
  assert.equal(back, 1200, "Back after a reload did not restore the scroll position");
  return `Back after reload ${back}`;
});

const panelTop = (page) => page.evaluate(() => Math.round(document.querySelector("#long-panel").scrollTop));

async function scrollPanel(page, y) {
  await page.evaluate((y) => document.querySelector("#long-panel").scrollTo(0, y), y);
  await page.waitForFunction((y) => Math.round(document.querySelector("#long-panel").scrollTop) === y, y);
}

async function waitForPanel(page, y) {
  await page
    .waitForFunction((y) => Math.round(document.querySelector("#long-panel")?.scrollTop) === y, y, { timeout: 5_000 })
    .catch(() => null);
  return panelTop(page);
}

check("scroll container restores on Back and after a reload", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e/long`);
  await ready(page, ".long-back");
  await scrollPanel(page, 600);
  await page.evaluate(() => document.querySelector(".long-back").click());
  await page.waitForSelector("#e2e-page");
  await page.goBack();
  await page.waitForSelector("#e2e-long");
  const back = await waitForPanel(page, 600);
  await scrollPanel(page, 900);
  await page.evaluate(() => document.querySelector(".long-back").click());
  await page.waitForSelector("#e2e-page");
  await page.reload();
  await ready(page, "#plain-route");
  await page.goBack();
  await page.waitForSelector("#e2e-long");
  const afterReload = await waitForPanel(page, 900);
  await page.reload();
  await ready(page, ".long-back");
  const reloaded = await waitForPanel(page, 900);
  assert.equal(back, 600, "Back did not restore the container position");
  assert.equal(afterReload, 900, "Back after a reload did not restore the container position");
  assert.equal(reloaded, 900, "a reload did not restore the container position");
  return `Back ${back}, Back after reload ${afterReload}, reload ${reloaded}`;
});

check("reload paints the saved scroll position on its first frame", async ({ page, origin }) => {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Emulation.setCPUThrottlingRate", { rate: 4 });
  await page.addInitScript(() =>
    requestAnimationFrame(() => {
      window.__firstFrame = Math.round(window.scrollY);
    }),
  );
  await page.goto(`${origin}/demo/router/e2e/long`);
  await ready(page, ".long-back");
  await scrollTo(page, 1500);
  await page.reload();
  await ready(page, ".long-back");
  const firstFrame = await page.evaluate(() => window.__firstFrame);
  const settled = await waitForScroll(page, 1500);
  assert.equal(firstFrame, 1500, "the reload painted another position before restoring");
  assert.equal(settled, 1500, "the reload did not keep the scroll position");
  return `first frame ${firstFrame}, settled ${settled}`;
});

check("redirect is followed on the client", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#navigate-redirect");
  const length = await page.evaluate(() => history.length);
  const mark = net.mark();
  await page.click("#navigate-redirect");
  await page.waitForSelector("#e2e-long");
  const after = net.since(mark);
  assert.equal(pathOf(page), "/demo/router/e2e/long");
  assert.equal(after.filter((r) => r.document).length, 0, "a document request was made");
  assert.equal(await page.evaluate(() => history.length), length + 1, "the redirect did not add one entry");
  return `requests: ${JSON.stringify(after.filter((r) => r.rsc && !r.prefetch).map((r) => r.url))}, history +1`;
});

check("server function redirect lands on the target", async ({ page, net, origin }) => {
  const redirects = [];
  page.on("response", (response) => {
    const href = response.headers()["router-redirect"];
    if (href) redirects.push([response.request().method(), new URL(response.url()).pathname, href]);
  });
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#redirect-action");
  const length = await page.evaluate(() => history.length);
  const mark = net.mark();
  await page.click("#redirect-action");
  await page.waitForSelector("#e2e-long");
  const after = net.since(mark);
  assert.equal(pathOf(page), "/demo/router/e2e/long");
  assert.equal(after.filter((r) => r.document).length, 0, "a document request was made");
  assert.deepEqual(redirects, [["POST", "/", "/demo/router/e2e/long"]]);
  assert.equal(await page.evaluate(() => history.length), length + 1, "the redirect was not a push");
  return `action responses ${JSON.stringify(redirects)}, navigation requests ${navigations(after, "/demo/router/e2e/long").length}, history +1`;
});

check("aria-current on Link after hydration, no hydration warnings", async ({ page, net, origin }) => {
  const response = await page.goto(`${origin}/demo/router/e2e`);
  const html = await response.text();
  await ready(page, ".link-self");
  await page.waitForLoadState("load");
  const self = await page.getAttribute(".link-self", "aria-current");
  const other = await page.getAttribute(".link-long", "aria-current");
  assert.match(html, /class="link-self"[^>]*aria-current="page"|aria-current="page"[^>]*class="link-self"/, "SSR did not render aria-current");
  assert.equal(self, "page");
  assert.equal(other, null);
  assert.deepEqual(reactConsole(net), [], "React errors or warnings in the console");
  return `self=${self}, other=${other}, console errors: []`;
});

check("live region announces the new title", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".link-long");
  const before = await page.textContent("[data-router-announcer]");
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  await page.waitForFunction(() => {
    const region = document.querySelector("[data-router-announcer]");
    return region && region.textContent !== "" && region.textContent === document.title;
  });
  const after = await page.textContent("[data-router-announcer]");
  const live = await page.getAttribute("[data-router-announcer]", "aria-live");
  assert.equal(before, "");
  assert.equal(live, "polite");
  return `region text "${after}" equals the title`;
});

check("view transitions set data-router-nav", async ({ page, origin }) => {
  await page.addInitScript(() => {
    window.__routerNav = [];
    new MutationObserver(() => {
      const value = document.documentElement?.getAttribute("data-router-nav");
      if (value) window.__routerNav.push(value);
    }).observe(document, { attributes: true, subtree: true, attributeFilter: ["data-router-nav"] });
  });
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".link-long");
  const supported = await page.evaluate(() => typeof document.startViewTransition === "function");
  assert.ok(supported, "startViewTransition is not supported");
  const transitionDone = (count) =>
    page.waitForFunction(
      (count) => window.__routerNav.length === count && !document.documentElement.hasAttribute("data-router-nav"),
      count,
    );
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  await transitionDone(1);
  await page.goBack();
  await page.waitForSelector("#e2e-page");
  await transitionDone(2);
  const seen = await page.evaluate(() => window.__routerNav);
  assert.deepEqual(seen, ["push", "back"]);
  return `seen ${JSON.stringify(seen)}, removed after each transition`;
});

check("blocker holds Back and proceed resumes it", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e/long`);
  await ready(page, ".long-back");
  await page.click(".long-back");
  await ready(page, "#toggle-blocker");
  await page.click("#toggle-blocker");
  await page.waitForFunction(() => document.querySelector("#toggle-blocker").textContent === "Stop blocking");
  await page.evaluate(() => history.back());
  await page.waitForSelector("#blocker-proceed");
  await page.waitForFunction(() => location.pathname === "/demo/router/e2e");
  const state = await page.textContent("#blocker-state");
  const heldUrl = pathOf(page);
  await page.click("#blocker-proceed");
  await page.waitForSelector("#e2e-long");
  assert.equal(pathOf(page), "/demo/router/e2e/long");
  return `held at ${heldUrl} (${state}), after proceed ${pathOf(page)}`;
});

check("blocker cancel keeps the page and history", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e/long`);
  await ready(page, ".long-back");
  await page.click(".long-back");
  await ready(page, "#toggle-blocker");
  await page.click("#toggle-blocker");
  await page.waitForFunction(() => document.querySelector("#toggle-blocker").textContent === "Stop blocking");
  await page.evaluate(() => history.back());
  await page.click("#blocker-cancel");
  await page.waitForFunction(() => document.querySelector("#blocker-state")?.textContent === "unblocked");
  assert.equal(pathOf(page), "/demo/router/e2e");
  await page.click("#toggle-blocker");
  await page.waitForFunction(() => document.querySelector("#toggle-blocker").textContent === "Block navigation");
  await page.evaluate(() => history.back());
  await page.waitForSelector("#e2e-long");
  return "after cancel the page stayed, and Back works once the blocker is off";
});

check("blocker asks before a reload", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#toggle-blocker");
  await page.click("#toggle-blocker");
  await page.waitForFunction(() => document.querySelector("#toggle-blocker").textContent === "Stop blocking");
  const dialog = page.waitForEvent("dialog", { timeout: 5_000 });
  const reload = page.reload().catch(() => null);
  const shown = await dialog;
  const type = shown.type();
  await shown.dismiss();
  await reload;
  assert.equal(type, "beforeunload");
  return `dialog ${type}`;
});

check("hover prefetches once and the click uses the cache", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".link-long");
  const mark = net.mark();
  const prefetched = prefetchOf(page, "/demo/router/e2e/long", "intent");
  await page.hover(".link-long");
  await (await prefetched).finished();
  await page.mouse.move(0, 0);
  await page.hover(".link-long");
  await absenceWindow(page);
  const prefetches = net.since(mark).filter((r) => r.url === "/demo/router/e2e/long" && r.prefetch);
  assert.deepEqual(prefetches.map((r) => r.prefetch), ["intent"], "expected one intent prefetch");
  const click = net.mark();
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  const after = net.since(click).filter((r) => r.url === "/demo/router/e2e/long");
  assert.equal(after.length, 0, "the click sent a request");
  return `prefetch headers ${JSON.stringify(prefetches.map((r) => r.prefetch))}, requests on click: 0`;
});

check("viewport prefetch", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".link-viewport");
  await page.waitForLoadState("load");
  const before = net.requests.filter((r) => r.url === "/demo/router/e2e/viewport").length;
  const prefetched = prefetchOf(page, "/demo/router/e2e/viewport", "viewport");
  await page.evaluate(() => document.querySelector(".link-viewport").scrollIntoView());
  await prefetched;
  const prefetches = net.requests.filter((r) => r.url === "/demo/router/e2e/viewport" && r.prefetch);
  assert.equal(before, 0, "the viewport link was prefetched before it was near the viewport");
  assert.deepEqual(prefetches.map((r) => r.prefetch), ["viewport"]);
  return `prefetch headers ${JSON.stringify(prefetches.map((r) => r.prefetch))}`;
});

check("refused prefetch is not asked again", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#plain-off");
  await page.hover(".link-off");
  await absenceWindow(page);
  const fromLink = net.requests.filter((r) => r.url === "/demo/router/e2e/off" && r.prefetch).length;
  const refused = prefetchOf(page, "/demo/router/e2e/off", "intent");
  await page.hover("#plain-off");
  const response = await refused;
  const status = [response.status(), response.headers()["router-prefetch-refused"] ?? null];
  await page.mouse.move(0, 0);
  await page.hover("#plain-off");
  await absenceWindow(page);
  const asked = net.requests.filter((r) => r.url === "/demo/router/e2e/off" && r.prefetch);
  assert.equal(fromLink, 0, "a Link to an Off route was prefetched");
  assert.deepEqual(status, [204, "off"]);
  assert.equal(asked.length, 1, "the refused URL was asked again");
  return `Link to Off route: 0 requests; plain anchor: 1 request, response ${JSON.stringify(status)}`;
});

check("Back reads the cache", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".link-long");
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  await page.click(".long-back");
  await page.waitForSelector("#e2e-page");
  const mark = net.mark();
  await page.goBack();
  await page.waitForSelector("#e2e-long");
  const after = net.since(mark).filter((r) => (r.rsc && !r.prefetch) || r.document);
  assert.deepEqual(after, [], "Back sent a request");
  return "requests on Back: []";
});

check("a page reached by a patch renders from the cache with its scroll", async ({ page, net, origin }) => {
  const kinds = [];
  page.on("response", (response) => {
    const kind = response.headers()["router-response"];
    if (kind && !response.request().headers()["router-prefetch"]) kinds.push([new URL(response.url()).pathname, kind]);
  });
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".link-long");
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  await page.click(".long-back");
  await page.waitForSelector("#e2e-page");
  await scrollTo(page, 900);
  await page.evaluate(() => document.querySelector(".link-long").click());
  await page.waitForSelector("#e2e-long");
  const mark = net.mark();
  await page.goBack();
  await page.waitForSelector("#e2e-page");
  const restored = await waitForScroll(page, 900);
  const parts = await page.$$eval("#plain-route, #toggle-blocker, .link-viewport", (elements) => elements.length);
  const after = net.since(mark).filter((r) => (r.rsc && !r.prefetch) || r.document);
  assert.deepEqual(kinds, [["/demo/router/e2e/long", "full"], ["/demo/router/e2e", "patch"], ["/demo/router/e2e/long", "patch"]]);
  assert.deepEqual(after, [], "Back to a patched page sent a request");
  assert.equal(parts, 3, "the cached page is missing parts of the patched page");
  assert.equal(restored, 900, "the cached page did not restore its scroll position");
  await page.click("#toggle-blocker");
  await page.waitForFunction(() => document.querySelector("#toggle-blocker").textContent === "Stop blocking");
  return `responses ${JSON.stringify(kinds)}, requests on Back: [], scroll ${restored}, client component works`;
});

check("hash-only navigate sends no request and scrolls to the fragment", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#navigate-hash");
  const mark = net.mark();
  await page.click("#navigate-hash");
  await page.waitForURL(`${origin}/demo/router/e2e#section`);
  await page.waitForFunction(() => Math.abs(document.querySelector("#section").getBoundingClientRect().top) <= 2);
  const after = net.since(mark).filter((r) => (r.rsc && !r.prefetch) || r.document);
  assert.deepEqual(after, [], "the hash change sent a request");
  return "requests: [], section at the top";
});

check("navigate to the current URL adds no entry and sends no request", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#navigate-current");
  const length = await page.evaluate(() => history.length);
  const mark = net.mark();
  await page.click("#navigate-current");
  await page.waitForFunction(() => document.querySelector("#navigate-result").textContent.startsWith("committed"));
  const result = await page.textContent("#navigate-result");
  await page.click(".link-self");
  await page.click("#plain-self");
  await absenceWindow(page);
  const after = net.since(mark).filter((r) => (r.rsc && !r.prefetch) || r.document);
  assert.equal(result, "committed /demo/router/e2e");
  assert.deepEqual(after, [], "navigating to the current URL sent a request");
  assert.equal(await page.evaluate(() => history.length), length, "navigating to the current URL added an entry");
  assert.equal(page.url(), `${origin}/demo/router/e2e`);
  return `navigate, Link and a plain anchor: ${result}, requests [], history +0`;
});

check("navigate to the current URL with revalidate navigates", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#navigate-current-revalidate");
  const length = await page.evaluate(() => history.length);
  const mark = net.mark();
  await page.click("#navigate-current-revalidate");
  await page.waitForFunction(() => document.querySelector("#navigate-result").textContent.startsWith("committed"));
  const asked = navigations(net.since(mark), "/demo/router/e2e").length;
  assert.equal(asked, 1, "expected one navigation request");
  assert.equal(await page.evaluate(() => history.length), length + 1, "the navigation did not add one entry");
  return `navigation requests ${asked}, history +1`;
});

check("navigate to the committed URL cancels a pending navigation", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#navigate-current");
  let release;
  const held = new Promise((resolve) => (release = resolve));
  await page.route("**/demo/router/e2e/long", async (route) => {
    if (route.request().headers()["router-prefetch"]) return route.continue();
    await held;
    await route.continue().catch(() => null);
  });
  const mark = net.mark();
  const pending = page.waitForRequest(
    (request) =>
      new URL(request.url()).pathname === "/demo/router/e2e/long" && !request.headers()["router-prefetch"],
  );
  await page.evaluate(() => document.querySelector(".link-long").click());
  await pending;
  await page.evaluate(() => document.querySelector("#navigate-current").click());
  await page.waitForFunction(() => document.querySelector("#navigate-result").textContent.startsWith("committed"));
  release();
  await absenceWindow(page);
  const asked = navigations(net.since(mark), "/demo/router/e2e").length;
  assert.equal(asked, 1, "navigating back to the committed URL did not run");
  assert.equal(pathOf(page), "/demo/router/e2e");
  assert.ok((await page.$("#e2e-long")) === null, "the pending navigation committed");
  return `navigation requests to the committed URL ${asked}, stayed on the page`;
});

check("hook functions keep their identity across navigations and search updates", async ({ page, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#navigate-current-revalidate");
  await page.click("#search-update");
  await page.waitForURL(`${origin}/demo/router/e2e?text=identity`);
  await page.click("#navigate-current-revalidate");
  await page.waitForFunction(() => document.querySelector("#navigate-result").textContent.startsWith("committed"));
  await page.click("#rerender");
  await absenceWindow(page);
  const mounted = await page.textContent("#hook-identity");
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  await page.click(".layout-e2e");
  await page.waitForSelector("#hook-identity");
  await page.click("#toggle-blocker");
  await page.click(".link-long");
  await page.waitForFunction(() => document.querySelector("#blocker-state").textContent.startsWith("blocked"));
  await page.click("#rerender");
  await absenceWindow(page);
  const remounted = await page.textContent("#hook-identity");
  assert.equal(mounted, "stable", "after a search update and a navigation");
  assert.equal(remounted, "stable", "after leaving the page, coming back and holding a navigation");
  return `after a search update and a navigation: ${mounted}; after a remount and a held navigation: ${remounted}`;
});

check("server function invalidates the cache", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, 'a[href="/demo/router/0"]');
  await page.click('a[href="/demo/router/0"]');
  await page.waitForFunction(() => document.querySelector("main")?.innerText.includes("Lorem ipsum for markdown, exists"));
  await page.goBack();
  await ready(page, "#server-action");
  await page.click("#server-action");
  await page.waitForFunction(() => document.querySelector("#action-state")?.textContent === "done");
  const mark = net.mark();
  await page.goForward();
  await page.waitForFunction(() => document.querySelector("main")?.innerText.includes("Edited by the router checks"));
  const after = navigations(net.since(mark), "/demo/router/0");
  assert.equal(after.length, 1, "Forward did not ask the server after the server function");
  return `requests on Forward: ${after.length}`;
});

check("page form without JavaScript posts once and shows the change", async ({ browser, origin }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();
  const exchanges = [];
  page.on("response", (response) => {
    if (new URL(response.url()).pathname === "/demo/router/e2e") {
      exchanges.push(`${response.request().method()} ${response.status()}`);
    }
  });
  try {
    await page.goto(`${origin}/demo/router/e2e`);
    const before = Number(await page.textContent("#visits"));
    await Promise.all([page.waitForNavigation(), page.click("#count-visit")]);
    const after = Number(await page.textContent("#visits"));
    const url = pathOf(page);
    await page.reload();
    const reloaded = Number(await page.textContent("#visits"));
    assert.equal(url, "/demo/router/e2e");
    assert.equal(after, before + 1, "the form post did not change the page");
    assert.equal(reloaded, after, "the reload posted again");
    assert.deepEqual(exchanges, ["GET 200", "POST 303", "GET 200", "GET 200"]);
    return `visits ${before} -> ${after}, after reload ${reloaded}, exchanges ${JSON.stringify(exchanges)}`;
  } finally {
    await context.close();
  }
});

check("layout links move aria-current after a patch and a search update", async ({ page, net, origin }) => {
  const kinds = [];
  page.on("response", (response) => {
    const kind = response.headers()["router-response"];
    if (kind && !response.request().headers()["router-prefetch"]) kinds.push(kind);
  });
  const current = () =>
    page.evaluate(() => ({
      e2e: document.querySelector(".layout-e2e").getAttribute("aria-current"),
      long: document.querySelector(".layout-long").getAttribute("aria-current"),
    }));
  const expectCurrent = (expected) =>
    page.waitForFunction(
      (expected) =>
        document.querySelector(".layout-e2e").getAttribute("aria-current") === expected.e2e &&
        document.querySelector(".layout-long").getAttribute("aria-current") === expected.long,
      expected,
      { timeout: 5_000 },
    ).catch(() => null);
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, ".layout-long");
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  await page.click(".long-back");
  await page.waitForSelector("#e2e-page");
  await expectCurrent({ e2e: "page", long: null });
  const afterPatchBack = await current();
  await page.click(".link-long");
  await page.waitForSelector("#e2e-long");
  await expectCurrent({ e2e: null, long: "page" });
  const afterPatch = await current();
  await page.fill("#sidebar-search-input", "x");
  await page.waitForFunction(() => location.search.includes("text=x"));
  await expectCurrent({ e2e: null, long: null });
  const afterSearch = await current();
  assert.deepEqual(kinds, ["full", "patch", "patch"], "the navigations were not patches");
  assert.deepEqual(afterPatchBack, { e2e: "page", long: null });
  assert.deepEqual(afterPatch, { e2e: null, long: "page" });
  assert.deepEqual(afterSearch, { e2e: null, long: null });
  assert.deepEqual(reactConsole(net), [], "React errors or warnings in the console");
  return `responses ${JSON.stringify(kinds)}; after patch to /e2e ${JSON.stringify(afterPatchBack)}, after patch to /e2e/long ${JSON.stringify(afterPatch)}, after updateSearch ${JSON.stringify(afterSearch)}`;
});

check("a prefetch that finishes after an invalidation is not used", async ({ page, net, origin }) => {
  let release;
  const released = new Promise((resolve) => (release = resolve));
  let held = false;
  await page.route("**/demo/router/1", async (route) => {
    if (!route.request().headers()["router-prefetch"]) return route.continue();
    held = true;
    const response = await route.fetch();
    await released;
    await route.fulfill({ response }).catch(() => null);
  });
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#server-action-1");
  const prefetchStarted = page.waitForRequest(
    (request) => new URL(request.url()).pathname === "/demo/router/1" && request.headers()["router-prefetch"],
  );
  await page.hover('a[href="/demo/router/1"]');
  await prefetchStarted;
  await page.click("#server-action-1");
  await page.waitForFunction(() => document.querySelector("#action-state")?.textContent === "done");
  release();
  await page.waitForTimeout(0);
  const mark = net.mark();
  await page.click('a[href="/demo/router/1"]');
  await page.waitForFunction(() => document.querySelector("main")?.innerText.includes("Edited note 1"), null, { timeout: 10_000 });
  const asked = navigations(net.since(mark), "/demo/router/1").length;
  assert.ok(held, "the prefetch was not held");
  assert.equal(asked, 1, "the click did not ask the server");
  return `late prefetch held and released after the server function; the click asked the server (${asked}) and shows "Edited note 1"`;
});

check("error pages are not cached", async ({ page, net, origin }) => {
  const statuses = [];
  page.on("response", (response) => {
    if (new URL(response.url()).pathname === "/demo/router/999" && response.headers()["router-response"]) {
      statuses.push([response.request().headers()["router-prefetch"] ?? "navigation", response.status()]);
    }
  });
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#plain-missing-note");
  const prefetched = prefetchOf(page, "/demo/router/999", "intent");
  await page.hover("#plain-missing-note");
  await (await prefetched).finished();
  const click = net.mark();
  await page.click("#plain-missing-note");
  await page.waitForFunction(() => document.querySelector("main")?.innerText.includes("No route matches this location") || document.querySelector("main")?.innerText.includes("could not be loaded"));
  const onClick = navigations(net.since(click), "/demo/router/999").length;
  await page.goBack();
  await page.waitForSelector("#e2e-page");
  const pop = net.mark();
  await page.goForward();
  await page.waitForURL(`${origin}/demo/router/999`);
  await page.waitForFunction(() => !document.querySelector("#e2e-page"));
  await page.waitForResponse((r) => new URL(r.url()).pathname === "/demo/router/999").catch(() => null);
  const onForward = navigations(net.since(pop), "/demo/router/999").length;
  assert.equal(onClick, 1, "the click used a cached error page");
  assert.equal(onForward, 1, "Forward used a cached error page");
  return `responses ${JSON.stringify(statuses)}; navigation requests on click ${onClick}, on Forward ${onForward}`;
});

check("a script URL in Router-Redirect is refused", async ({ page, origin }) => {
  const dialogs = [];
  page.on("dialog", async (dialog) => {
    dialogs.push(dialog.message());
    await dialog.dismiss();
  });
  await page.route("**/", async (route) => {
    const request = route.request();
    if (request.method() !== "POST" || !request.headers()["action_id"]) return route.continue();
    const response = await route.fetch();
    await route.fulfill({ response, headers: { ...response.headers(), "router-redirect": "javascript:window.__routerPwned=1;alert(1)" } });
  });
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#redirect-action");
  const before = page.url();
  const answered = page.waitForResponse((r) => r.request().method() === "POST" && new URL(r.url()).pathname === "/");
  await page.click("#redirect-action");
  const response = await answered;
  await absenceWindow(page);
  const pwned = await page.evaluate(() => window.__routerPwned ?? null);
  assert.equal(response.headers()["router-redirect"], "javascript:window.__routerPwned=1;alert(1)");
  assert.equal(pwned, null, "the script ran");
  assert.deepEqual(dialogs, [], "an alert opened");
  assert.equal(page.url(), before, "the page navigated");
  return `header ${JSON.stringify(response.headers()["router-redirect"])}, script did not run, URL unchanged`;
});

check("a shallow entry with a malformed pair stays on the client", async ({ page, net, origin }) => {
  await page.goto(`${origin}/demo/router/e2e`);
  await ready(page, "#e2e-page");
  await page.evaluate(() => history.pushState(history.state, "", "/demo/router/e2e?text=%FF"));
  await page.evaluate(() => history.back());
  await page.waitForFunction(() => location.search === "");
  const mark = net.mark();
  await page.evaluate(() => history.forward());
  await page.waitForFunction(() => location.search === "?text=%FF");
  await absenceWindow(page);
  const asked = navigations(net.since(mark), "/demo/router/e2e?text=%FF").length;
  const kept = (await page.$("#e2e-page")) !== null;
  const documentResponse = await page.goto(`${origin}/demo/router/e2e?text=%FF`);
  assert.equal(asked, 0, "the client asked the server");
  assert.ok(kept, "the client left the page");
  assert.equal(documentResponse.status(), 200);
  return `navigation requests ${asked}, page kept, document load status ${documentResponse.status()}`;
});

const server = await startServer();
const browser = await chromium.launch({ executablePath: await chromiumPath() });
let failures = 0;
let ran = 0;
try {
  for (const { name, run } of checks) {
    if (only && !name.includes(only)) continue;
    ran++;
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();
    const net = watch(page);
    try {
      const detail = await run({ page, net, origin: server.origin, browser });
      console.log(`PASS ${name}: ${detail}`);
    } catch (error) {
      failures++;
      console.log(`FAIL ${name}: ${error.message.split("\n")[0]}`);
      if (error.actual !== undefined || error.expected !== undefined) {
        console.log(`  actual ${JSON.stringify(error.actual)} expected ${JSON.stringify(error.expected)}`);
      }
      if (net.console.length) console.log(`  console: ${JSON.stringify(net.console)}`);
      if (net.failed.length) console.log(`  failed responses: ${JSON.stringify(net.failed)}`);
    }
    await context.close();
  }
} finally {
  await browser.close();
  server.stop();
}
console.log(`${ran - failures}/${ran} checks passed`);
process.exit(failures === 0 ? 0 : 1);
