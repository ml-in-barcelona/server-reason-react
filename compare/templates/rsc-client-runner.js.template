import { pathToFileURL } from "node:url";
import { readFileSync } from "node:fs";

process.env.NODE_ENV = "production";

const { renderToPipeableStream, registerClientReference } = await import(
  "react-server-dom-webpack/server"
);
const React = await import("react");

const appModulePath = process.argv[2];
if (!appModulePath) {
  console.error("Usage: runner.js <app-module-path>");
  process.exit(2);
}

const appSource = readFileSync(appModulePath, "utf-8");
const extractMatch = appSource.match(/\/\/\s*extract-client\s+(.+)/);
if (!extractMatch) {
  console.error("No // extract-client marker found in compiled module");
  process.exit(2);
}

const [moduleId, ...modules] = extractMatch[1].trim().split(/\s+/);
const moduleReference = moduleId + "#" + modules.join(".");
const clientManifest = {
  [moduleReference]: { id: moduleReference, chunks: [], name: "", async: false },
};

const ref = registerClientReference({}, moduleReference, "");
const app = React.createElement(ref, {});

const { pipe } = renderToPipeableStream(app, clientManifest, {
  onError(error) {
    console.error(error);
    process.exitCode = 1;
  },
});

pipe(process.stdout);
