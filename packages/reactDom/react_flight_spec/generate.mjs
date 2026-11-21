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

function normalizeRow(row) {
  return row
    .replace(/"stack":(\[[^\]]*\]|".*?")/g, '"stack":"<stack>"')
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
      onError() {},
    });
    pipe(sink);
  });
  return toRows(Buffer.concat(chunks).toString("utf8"));
}

const { runFixtureSuite } = await import(path.join(here, "fixture-suite.mjs"));

await runFixtureSuite({
  cases: listItems(all),
  fixturePath: (kase) => path.join(here, "fixtures", `${kase.name}.flight`),
  produce: async (kase) => (await renderCase(kase)).join("\n") + "\n",
  printDiff: (_kase, committed, produced) => {
    const committedRows = toRows(committed);
    const rows = toRows(produced);
    const max = Math.max(committedRows.length, rows.length);
    for (let i = 0; i < max; i += 1) {
      if (committedRows[i] !== rows[i]) {
        console.error(`  row ${i}:`);
        console.error(`    fixture:  ${committedRows[i] ?? "<missing>"}`);
        console.error(`    rendered: ${rows[i] ?? "<missing>"}`);
      }
    }
  },
  label: "cases",
  regenCommand: "make spec-generate",
  check,
});
