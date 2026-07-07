// Renders every spec case through the REAL react-server-dom-webpack and
// writes the resulting Flight payload (one row per line, normalized) to
// fixtures/<case>.flight.
//
// Run from this directory with:
//   NODE_ENV=production bun --conditions react-server generate.mjs [--check]
//
// --check: re-render and diff against the committed fixtures instead of
// writing; exits non-zero (with a printed diff) on any mismatch.

import * as fs from "node:fs";
import * as path from "node:path";
import { Writable } from "node:stream";
import { fileURLToPath } from "node:url";

process.env.NODE_ENV ??= "production";
if (process.env.NODE_ENV !== "production") {
  console.error(`NODE_ENV=${process.env.NODE_ENV}; fixtures are only defined for production`);
  process.exit(1);
}

const here = path.dirname(fileURLToPath(import.meta.url));
const check = process.argv.includes("--check");

// ---------------------------------------------------------------------------
// Locate the melange-emitted cases and copy them next to this file so that
// bare imports (react, react/jsx-runtime, react-server-dom-webpack/server)
// resolve against the exact-pinned node_modules of this directory.
// ---------------------------------------------------------------------------

const repoRoot = path.resolve(here, "../../..");
const emitRoot = path.join(repoRoot, "_build/default/packages/reactDom/react_flight_spec/cases/js/flight");
const localOut = path.join(here, ".melange-out");

if (!fs.existsSync(emitRoot)) {
  console.error(`Melange output not found at ${emitRoot}.`);
  console.error("Run: dune build @packages/reactDom/react_flight_spec/melange");
  process.exit(1);
}

fs.rmSync(localOut, { recursive: true, force: true });
fs.cpSync(emitRoot, localOut, { recursive: true, dereference: true });

const { all } = await import(
  path.join(localOut, "packages/reactDom/react_flight_spec/cases/js/Cases.mjs")
);
const { renderToPipeableStream } = await import("react-server-dom-webpack/server");

// ---------------------------------------------------------------------------
// Client manifest: echo module/name back so `I` rows come out as
// ["<module>",[],"<name>"], byte-matching srr's [import_module, [], import_name].
// ---------------------------------------------------------------------------

const clientManifest = new Proxy(
  {},
  {
    get(_target, key) {
      if (typeof key !== "string") return undefined;
      const hash = key.lastIndexOf("#");
      if (hash === -1) return undefined;
      return { id: key.slice(0, hash), chunks: [], name: key.slice(hash + 1) };
    },
  },
);

// ---------------------------------------------------------------------------
// Normalization: keep in sync with conformance/flight_spec_conformance.ml and
// the rules documented in protocol.md.
// ---------------------------------------------------------------------------

function normalizeRow(row) {
  return row
    .replace(/"stack":(\[.*?\]|".*?")/g, '"stack":"<stack>"')
    .replace(/"digest":"[^"]*"/g, '"digest":"<digest>"');
}

function toRows(payload) {
  const rows = payload.split("\n");
  if (rows.at(-1) === "") rows.pop();
  return rows.map(normalizeRow);
}

function* listItems(melangeList) {
  for (let cell = melangeList; cell !== 0; cell = cell.tl) yield cell.hd;
}

async function renderCase(kase) {
  const chunks = [];
  await new Promise((resolve, reject) => {
    const sink = new Writable({
      write(chunk, _encoding, callback) {
        chunks.push(chunk);
        callback();
      },
      final(callback) {
        callback();
        resolve();
      },
    });
    sink.on("error", reject);
    const { pipe } = renderToPipeableStream(kase.render(), clientManifest, {
      onError(error) {
        reject(error instanceof Error ? error : new Error(String(error)));
      },
    });
    pipe(sink);
  });
  return toRows(Buffer.concat(chunks).toString("utf8"));
}

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------

const fixturesDir = path.join(here, "fixtures");
fs.mkdirSync(fixturesDir, { recursive: true });

let failures = 0;
let count = 0;

for (const kase of listItems(all)) {
  count += 1;
  const fixturePath = path.join(fixturesDir, `${kase.name}.flight`);
  const rows = await renderCase(kase);
  const rendered = rows.join("\n") + "\n";

  if (check) {
    if (!fs.existsSync(fixturePath)) {
      console.error(`FAIL ${kase.name}: fixture missing (${fixturePath})`);
      failures += 1;
      continue;
    }
    const committed = fs.readFileSync(fixturePath, "utf8");
    if (committed !== rendered) {
      failures += 1;
      console.error(`FAIL ${kase.name}: fixture out of date`);
      const committedRows = toRows(committed);
      const max = Math.max(committedRows.length, rows.length);
      for (let i = 0; i < max; i += 1) {
        if (committedRows[i] !== rows[i]) {
          console.error(`  row ${i}:`);
          console.error(`    fixture:  ${committedRows[i] ?? "<missing>"}`);
          console.error(`    rendered: ${rows[i] ?? "<missing>"}`);
        }
      }
    } else {
      console.log(`ok   ${kase.name}`);
    }
  } else {
    fs.writeFileSync(fixturePath, rendered);
    console.log(`wrote fixtures/${kase.name}.flight (${rows.length} row${rows.length === 1 ? "" : "s"})`);
  }
}

if (check && failures > 0) {
  console.error(`\n${failures}/${count} fixtures out of date. Run: make spec-generate`);
  process.exit(1);
}
console.log(`\n${count} cases ${check ? "checked" : "generated"} against react-server-dom-webpack.`);
