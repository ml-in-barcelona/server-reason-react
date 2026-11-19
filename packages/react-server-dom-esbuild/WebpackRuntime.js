/* react-server-dom-webpack stores load status on the promise, so return the same promise per id.
   It reads __webpack_require__.u at module evaluation, so evaluate this module before it. */
const modules = new Map();

function __webpack_require__(id) {
  let promise = modules.get(id);
  if (promise === undefined) {
    const entry = window.__client_manifest_map[id];
    promise = entry
      ? entry.load()
      : Promise.reject(new Error(`Could not find client component module with id: ${id}`));
    modules.set(id, promise);
  }
  return promise;
}

__webpack_require__.u = (chunkId) => chunkId;

globalThis.__webpack_require__ = __webpack_require__;
globalThis.__webpack_chunk_load__ = (chunkId) =>
  Promise.reject(new Error(`Unexpected client chunk: ${chunkId}`));
