import React from "react";
import { createRoot, hydrateRoot } from "react-dom/client";
import { createFromReadableStream } from "../../../react-server-dom-esbuild/ReactServerDOMEsbuild.js";

const state = (window.flightTest = {
  version: React.version,
  console: [],
  decodeErrors: [],
  renderErrors: [],
  recoverableErrors: [],
  streamClosed: false,
  commits: 0,
  clientCommits: 0,
  moduleLoads: 0,
  started: false,
});

function printable(value) {
  if (value instanceof Error) return value.stack || value.message;
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value) ?? String(value);
  } catch {
    return String(value);
  }
}

function format(args) {
  if (typeof args[0] !== "string") return args.map(printable).join(" ");
  let index = 1;
  const text = args[0].replace(/%[%sdifoOc]/g, (token) => {
    if (token === "%%") return "%";
    if (index >= args.length) return token;
    const value = args[index++];
    return token === "%c" ? "" : printable(value);
  });
  return [text, ...args.slice(index).map(printable)].join(" ");
}

for (const level of ["warn", "error"]) {
  const original = console[level].bind(console);
  console[level] = (...args) => {
    state.console.push({ level, args: args.map(printable), text: format(args) });
    original(...args);
  };
}

window.__client_manifest_map = {
  "key-validation-client": {
    load: async () => {
      state.moduleLoads++;
      return (await import("./client.mjs")).default;
    },
  },
};

function observedStream(source) {
  const reader = source.getReader();
  return new ReadableStream({
    async pull(controller) {
      const next = await reader.read();
      if (next.done) {
        state.streamClosed = true;
        controller.close();
      } else {
        controller.enqueue(next.value);
      }
    },
  });
}

function Root({ response, plain }) {
  let value;
  try {
    value = plain ?? React.use(response);
  } catch (error) {
    if (response?.status === "rejected") state.decodeErrors.push(printable(response.reason));
    throw error;
  }
  React.useEffect(() => {
    state.commits++;
  });
  return value;
}

function mount(source, { document: wholeDocument = false, hydrate = false, plain } = {}) {
  const response = source ? createFromReadableStream(observedStream(source)) : null;
  const element = React.createElement(Root, { response, plain });
  const target = wholeDocument ? document : document.getElementById("result");
  const options = {
    onUncaughtError: (error) => state.renderErrors.push(printable(error)),
    onRecoverableError: (error) => state.recoverableErrors.push(printable(error)),
  };
  if (hydrate) hydrateRoot(target, element, options);
  else createRoot(target, options).render(element);
  state.started = true;
}

window.startFlightTest = (fixture) => {
  if (fixture.plain) {
    state.streamClosed = true;
    const plain = React.createElement("div", null, [
      React.createElement("span", null, "a"),
      React.createElement("span", null, "b"),
    ]);
    mount(null, { plain });
    return;
  }
  const encoder = new TextEncoder();
  let release;
  const source = new ReadableStream({
    start(controller) {
      for (const chunk of fixture.chunks.slice(0, fixture.initialChunks)) {
        controller.enqueue(encoder.encode(chunk));
      }
      release = () => {
        for (const chunk of fixture.chunks.slice(fixture.initialChunks)) {
          controller.enqueue(encoder.encode(chunk));
        }
        controller.close();
      };
    },
  });
  window.releaseFlightTest = release;
  mount(source, fixture);
};

if (window.srr_stream) {
  mount(window.srr_stream.readable_stream, { document: true, hydrate: true });
}
