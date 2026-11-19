import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import path from "node:path";
import plugin from "../plugin.mjs";

const esbuild = createRequire(import.meta.url)(path.resolve(process.argv[2]));

const root = mkdtempSync(path.join(tmpdir(), "esbuild-plugin-"));
const target = path.join(root, "target");
mkdirSync(target);
const serverFunction = "// extract-server-function Actions#save save\nexports.save = {};\n";
writeFileSync(path.join(target, "A.js"), serverFunction);
writeFileSync(path.join(target, "B.js"), serverFunction);
const entry = path.join(root, "entry.js");
writeFileSync(entry, "console.log(1);\n");

const build = esbuild.build({
  entryPoints: [entry],
  write: false,
  logLevel: "silent",
  plugins: [plugin({ entrypoints: [entry], target, bootstrapOutput: path.join(root, "bootstrap.js") })],
});

await assert.rejects(build, (error) => {
  assert.equal(error.errors.length, 1);
  assert.match(error.errors[0].text, /duplicate server function id "Actions#save"/);
  return true;
});
