import React from "react";
import { renderToPipeableStream } from "react-server-dom-webpack/server";
import { pathToFileURL } from "node:url";

process.env.NODE_ENV = "production";

const entryPath = process.argv[2];
if (!entryPath) {
  console.error("Missing entry path");
  process.exit(2);
}

const entry = await import(pathToFileURL(entryPath).href);
const app = entry.app ?? entry.default?.app;
if (!app) {
  console.error("Entry module must export 'app'");
  process.exit(2);
}

const { pipe } = renderToPipeableStream(app, {
  onError(error) {
    console.error(error);
    process.exitCode = 1;
  },
});

pipe(process.stdout);
