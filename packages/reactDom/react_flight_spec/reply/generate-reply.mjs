// Encodes every reply spec case through the REAL React `encodeReply` (the
// public wrapper over processReply from react-server-dom-webpack/client) and
// writes the resulting server-function-call body to reply/fixtures/<case>.reply.
//
// Run from the react_flight_spec directory with:
//   NODE_ENV=production bun reply/generate-reply.mjs [--check]
//
// (plain bun: processReply/encodeReply is CLIENT-side code, no react-server
// condition. `client.browser` is imported explicitly because bun matches the
// `node` export condition, which resolves to a client build without
// encodeReply.)
//
// --check: re-encode and diff against the committed fixtures instead of
// writing; exits non-zero (with a printed diff) on any mismatch.
//
// Fixture format (see also ../protocol.md, "Reply fixtures"):
//   line 1: `string` or `formdata` — the type encodeReply returned.
//   string body: line 2 is the body verbatim (JSON never contains raw
//     newlines, so it is always a single line).
//   formdata body: one JSON array per line, in FormData insertion order:
//     ["string", <key>, <value>]  for text entries
//     ["blob", <key>, <base64>]   for Blob/File entries (content-type and
//                                 filename are not part of the fixture)
//   Every fixture ends with a trailing newline.

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

process.env.NODE_ENV ??= "production";
if (process.env.NODE_ENV !== "production") {
  console.error(`NODE_ENV=${process.env.NODE_ENV}; fixtures are only defined for production`);
  process.exit(1);
}

// client.browser is a webpack bundle target: it dereferences webpack's
// loader globals at module scope. encodeReply never loads modules, so inert
// shims are enough. Installed before any import of the client (cases.mjs
// re-exports from it, hence the dynamic imports below).
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

const fixturesDir = path.join(here, "fixtures");
fs.mkdirSync(fixturesDir, { recursive: true });

let failures = 0;
let count = 0;

for (const kase of cases) {
  count += 1;
  const fixturePath = path.join(fixturesDir, `${kase.name}.reply`);
  const body = await encodeReply(kase.args(), kase.options?.());
  const serialized = await serializeBody(body);

  if (check) {
    if (!fs.existsSync(fixturePath)) {
      console.error(`FAIL ${kase.name}: fixture missing (${fixturePath})`);
      failures += 1;
      continue;
    }
    const committed = fs.readFileSync(fixturePath, "utf8");
    if (committed !== serialized) {
      failures += 1;
      console.error(`FAIL ${kase.name}: fixture out of date`);
      console.error(`  fixture: ${JSON.stringify(committed)}`);
      console.error(`  encoded: ${JSON.stringify(serialized)}`);
    } else {
      console.log(`ok   ${kase.name}`);
    }
  } else {
    fs.writeFileSync(fixturePath, serialized);
    console.log(`wrote reply/fixtures/${kase.name}.reply`);
  }
}

if (check && failures > 0) {
  console.error(`\n${failures}/${count} reply fixtures out of date. Run: make spec-generate-reply`);
  process.exit(1);
}
console.log(`\n${count} reply cases ${check ? "checked" : "generated"} against react-server-dom-webpack.`);
