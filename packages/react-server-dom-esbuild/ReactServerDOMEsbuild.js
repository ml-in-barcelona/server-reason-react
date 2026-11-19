import "./WebpackRuntime.js";
import {
  createFromFetch as createFromFetchImpl,
  createFromReadableStream as createFromReadableStreamImpl,
} from "react-server-dom-webpack/client.browser";

export { createServerReference, encodeReply } from "react-server-dom-webpack/client.browser";

function callCurrentServerCallback(callServer) {
  return function (id, args) {
    if (!callServer) {
      throw new Error(
        "No server callback has been registered. Pass callServer to createFromFetch or createFromReadableStream."
      );
    }
    return callServer(id, args);
  };
}

function responseOptions(options) {
  return {
    callServer: callCurrentServerCallback(options ? options.callServer : undefined),
    temporaryReferences: options ? options.temporaryReferences : undefined,
    replayConsoleLogs: false,
  };
}

/*
 * The Flight root chunk serves two consumers with conflicting needs:
 *
 * - React.use reads its `status`/`value` fields synchronously (hydration
 *   relies on that) and calls `then` for its side effect of registering
 *   callbacks and initializing lazy chunks.
 * - Promise chaining needs `then` to return a chained promise, but the
 *   chunk's `then` returns undefined, so chaining on it silently resolves
 *   undefined.
 *
 * Wrapping the chunk (Promise.resolve or a facade) breaks hydration: any
 * subscription at creation time forces the model to initialize as soon as
 * its row arrives, before referenced module chunks have loaded, and client
 * components resolve to null. Instead, repair `then` in place: it still
 * performs the original synchronous registration and initialization, and
 * additionally returns a real promise. Nothing subscribes until a consumer
 * does, so the chunk stays lazy.
 */
function chainableRoot(chunk) {
  const originalThen = chunk.then.bind(chunk);
  chunk.then = function (onFulfilled, onRejected) {
    return new Promise(originalThen).then(onFulfilled, onRejected);
  };
  return chunk;
}

export function createFromReadableStream(stream, options) {
  return chainableRoot(createFromReadableStreamImpl(stream, responseOptions(options)));
}

export function createFromFetch(promise, options) {
  return chainableRoot(createFromFetchImpl(promise, responseOptions(options)));
}
