import assert from "node:assert/strict";
import { createFromReadableStream } from "./ReactServerDOMEsbuild.mjs";

globalThis.window = globalThis;

const calls = [];
const record = {
  id: "Actions#save",
  call: (...args) => {
    calls.push(args);
    return Promise.resolve("saved");
  },
};
window.__server_functions_manifest_map = { "Actions#save": record };

const payload = '1:{"id":"Actions#save","bound":null}\n0:{"prop":"$F1","action":"$F1"}\n';
const stream = new ReadableStream({
  start(controller) {
    controller.enqueue(new TextEncoder().encode(payload));
    controller.close();
  },
});

const model = await createFromReadableStream(stream);

assert.equal(typeof model.action, "function", "a form action must be a function");
assert.equal(await model.action("form"), "saved");
assert.equal(model.prop.id, "Actions#save", "a client component prop must keep the record id");
assert.equal(await model.prop.call("form", 1), "saved");
assert.deepEqual(calls, [["form"], ["form", 1]]);
