import * as path from "node:path";
import { fileURLToPath } from "node:url";

process.env.NODE_ENV ??= "production";
if (process.env.NODE_ENV !== "production") {
  console.error(`NODE_ENV=${process.env.NODE_ENV}; fixtures are only defined for production`);
  process.exit(1);
}

globalThis.__webpack_require__ = Object.assign(() => ({}), { u: () => "" });
globalThis.__webpack_chunk_load__ = () => Promise.resolve();

const here = path.dirname(fileURLToPath(import.meta.url));
const check = process.argv.includes("--check");

const { encodeReply } = await import("react-server-dom-webpack/client.browser");
const { cases } = await import(path.join(here, "cases.mjs"));

async function serializeBody(body) {
  if (typeof body === "string") {
    return `string\n${body}\n`;
  }
  const lines = ["formdata"];
  for (const [key, value] of body.entries()) {
    if (typeof value === "string") {
      lines.push(JSON.stringify(["string", key, value]));
    } else {
      const bytes = Buffer.from(await value.arrayBuffer());
      lines.push(JSON.stringify(["blob", key, bytes.toString("base64")]));
    }
  }
  return lines.join("\n") + "\n";
}

const { runFixtureSuite } = await import(path.join(here, "..", "fixture-suite.mjs"));

await runFixtureSuite({
  cases,
  fixturePath: (kase) => path.join(here, "fixtures", `${kase.name}.reply`),
  produce: async (kase) => serializeBody(await encodeReply(kase.args(), kase.options?.())),
  printDiff: (_kase, committed, produced) => {
    console.error(`  fixture: ${JSON.stringify(committed)}`);
    console.error(`  encoded: ${JSON.stringify(produced)}`);
  },
  label: "reply cases",
  regenCommand: "make spec-generate-reply",
  check,
});
