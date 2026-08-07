// This script is used to build the React client pointing to our flight-entry.js
const Module = require("module");
const path = require("path");

const reactDir = path.join(__dirname, "react");
const buildScript = path.join(reactDir, "scripts/rollup/build.js");

const originalResolve = Module._resolveFilename;
Module._resolveFilename = function (request, ...rest) {
  return request === "react-client/flight"
    ? path.join(__dirname, "flight-entry.js")
    : originalResolve.call(this, request, ...rest);
};

process.chdir(reactDir);
process.argv = [process.argv[0], buildScript, "react-client"];
require(buildScript);
