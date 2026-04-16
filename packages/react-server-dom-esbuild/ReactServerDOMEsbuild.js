/*
 * This file is a bundler integration between react (react-client/flight), esbuild and server-reason-react.
 *
 * React's Flight client (`react-client/flight`) is a factory function that accepts a `$$$config`
 * object with bundler-specific implementations. Each official React integration (webpack, parcel, etc.)
 * provides its own config. This file is the esbuild-specific config for server-reason-react.
 *
 * The `$$$config` object is composed from three groups of options plus renderer metadata:
 *   1. **Stream config** — how to decode binary chunks from the RSC stream into strings.
 *   2. **Console config** — how to replay server-side console logs on the client (dev only).
 *   3. **Bundler config** — how to resolve and load client/server modules at runtime.
 *   4. **Renderer metadata** — version and package name for React DevTools integration.
 *
 * Similar resources:
 * - **react-server-dom-webpack**: https://github.com/facebook/react/blob/5c56b873efb300b4d1afc4ba6f16acf17e4e5800/packages/react-server-dom-webpack/src/ReactFlightWebpackPlugin.js#L156-L194
 * - **react-server-dom-parcel**: https://github.com/facebook/react/pull/31725
 *
 * ## Why `@pedrobslisboa/react-client`?
 *
 * React's `react-client` package (which provides the Flight protocol deserializer)
 * is an internal package that is NOT published to npm by the React team.
 * It is only consumed internally by React's own bundler integrations (webpack, parcel, esm).
 *
 * Since server-reason-react needs a custom esbuild integration, and `react-client`
 * is the intended extension point (via the `$$$config` injection pattern), Pedro
 * (a core contributor to server-reason-react) republished the package under
 * `@pedrobslisboa/react-client` so this project can use the Flight client factory directly.
 */

import ReactClientFlight from "@pedrobslisboa/react-client/flight";

const isDebug = false;

const debug = (...args) => {
  if (isDebug && process.env.NODE_ENV === "development") {
    console.log(...args);
  }
};

/*
 * Stream config — tells the Flight client how to decode binary chunks into strings.
 *
 * These three functions are called during `processBinaryChunk` to turn raw
 * `Uint8Array` buffers from the ReadableStream into string content that the
 * Flight protocol parser can process.
 */
const ReactFlightClientStreamConfigWeb = {
  /*
   * Creates a TextDecoder instance used for all subsequent string decoding.
   * Stored as `response._stringDecoder` on the Flight response object.
   */
  createStringDecoder() {
    return new TextDecoder();
  },

  /*
   * Decodes a partial binary chunk in streaming mode (`{ stream: true }`).
   * Called for every buffer segment except the last one in a row.
   * The `stream: true` option prevents the decoder from flushing incomplete
   * multi-byte characters, allowing them to be completed by subsequent chunks.
   */
  readPartialStringChunk(decoder, buffer) {
    return decoder.decode(buffer, { stream: true });
  },

  /*
   * Decodes the final binary chunk of a row (without `stream: true`).
   * This flushes any remaining bytes in the decoder's internal buffer.
   */
  readFinalStringChunk(decoder, buffer) {
    return decoder.decode(buffer);
  },
};

const badgeFormat = "%c%s%c ";

// Same badge styling as DevTools.
const badgeStyle =
  // We use a fixed background if light-dark is not supported, otherwise
  // we use a transparent background.
  "background: #e6e6e6;" +
  "background: light-dark(rgba(0,0,0,0.1), rgba(255,255,255,0.25));" +
  "color: #000000;" +
  "color: light-dark(#000000, #ffffff);" +
  "border-radius: 2px";

const resetStyle = "";
const pad = " ";

const bind = Function.prototype.bind;

/*
 * Console config — tells the Flight client how to replay server-side console
 * logs on the client with a badge indicating the server environment.
 *
 * In production builds, `bindToConsole` is extracted from the config but
 * never actually called (dead code). In development, it is called for each
 * replayed server console message with the method name, args, and environment
 * badge name.
 */
const ReactClientConsoleConfigBrowser = {
  /*
   * Wraps a console method call with badge formatting so that replayed
   * server logs appear with a visual tag (e.g., "[Server]") in the browser console.
   *
   * @param methodName - The console method (e.g., "log", "warn", "error", "assert")
   * @param args - The original arguments passed to the console method on the server
   * @param badgeName - The environment name to display as a badge (e.g., "Server")
   * @returns A bound console function ready to be called
   */
  bindToConsole(methodName, args, badgeName) {
    let offset = 0;
    switch (methodName) {
      case "dir":
      case "dirxml":
      case "groupEnd":
      case "table": {
        // These methods cannot be colorized because they don't take a formatting string.
        return bind.apply(console[methodName], [console].concat(args));
      }
      case "assert": {
        // assert takes formatting options as the second argument.
        offset = 1;
      }
    }

    const newArgs = args.slice(0);
    if (typeof newArgs[offset] === "string") {
      newArgs.splice(
        offset,
        1,
        badgeFormat + newArgs[offset],
        badgeStyle,
        pad + badgeName + pad,
        resetStyle
      );
    } else {
      newArgs.splice(
        offset,
        0,
        badgeFormat,
        badgeStyle,
        pad + badgeName + pad,
        resetStyle
      );
    }

    // The "this" binding in the "bind";
    newArgs.unshift(console);

    return bind.apply(console[methodName], newArgs);
  },
};

/* Indices into the metadata tuple returned by the RSC stream for client component references. */
const ID = 0;
const NAME = 1;
const BUNDLES = 2;

/*
 * Bundler config — tells the Flight client how to resolve and load modules.
 *
 * These functions bridge between the abstract module references in the RSC
 * stream and the actual runtime modules available in the browser. In the
 * esbuild integration, client components and server functions are registered
 * in global manifest maps (`window.__client_manifest_map` and
 * `window.__server_functions_manifest_map`) by the esbuild build plugin.
 */
const ReactFlightClientConfigBundlerEsbuild = {
  /*
   * Called when the Flight client encounters a client module reference in the stream.
   * Allows the integration to initiate loading of scripts/stylesheets needed by the module.
   *
   * In the esbuild integration this is a no-op because all client bundles are
   * already loaded via script tags — there's no dynamic chunk loading.
   *
   * @param moduleLoading - The `moduleLoading` config passed to `createResponse` (null for esbuild)
   * @param nonce - CSP nonce for script injection (undefined for esbuild)
   * @param metadata - The parsed module metadata from the RSC stream
   */
  prepareDestinationForModule(moduleLoading, nonce, metadata) {
    debug("prepareDestinationForModule", moduleLoading, nonce, metadata);
    return;
  },

  /*
   * Called to resolve a client component reference from the RSC stream into
   * a bundler-specific reference object. The returned object is later passed
   * to `preloadModule` and `requireModule`.
   *
   * In the esbuild integration, metadata comes as a tuple [id, name, bundles]
   * and we restructure it into a typed object.
   *
   * @param bundlerConfig - The `bundlerConfig` passed to `createResponse` (null for esbuild)
   * @param metadata - The serialized module reference from the RSC stream [id, name, bundles]
   * @returns An object with { type, id, name, bundles } used by `requireModule`
   */
  resolveClientReference(bundlerConfig, metadata) {
    debug("resolveClientReference", bundlerConfig, metadata);
    // Reference is already resolved during the build
    return {
      type: "ClientComponent",
      id: metadata[ID],
      name: metadata[NAME],
      bundles: metadata[BUNDLES],
    };
  },

  /*
   * Called to resolve a server function reference from the RSC stream.
   * Only called when `serverReferenceConfig` (second arg to `createResponse`)
   * is truthy. When falsy, server references fall back to `createBoundServerReference`
   * which uses `callServer` directly.
   *
   * @param bundlerConfig - The `serverReferenceConfig` passed to `createResponse` ({} for esbuild)
   * @param ref - The server reference ID string from the RSC stream
   * @returns An object with { type, id } used by `requireModule`
   */
  resolveServerReference(bundlerConfig, ref) {
    debug("resolveServerReference", bundlerConfig, ref);

    return {
      type: "ServerFunction",
      id: ref,
    };
  },

  /*
   * Called to optionally preload a module before it's required. Should return
   * a thenable/promise if async loading is needed, or a falsy value if the
   * module is already available synchronously.
   *
   * In the esbuild integration this always returns undefined because all modules
   * are pre-loaded via the global manifest maps.
   *
   * @param metadata - The resolved reference from `resolveClientReference` or `resolveServerReference`
   * @returns undefined (no preloading needed)
   */
  preloadModule(metadata) {
    debug("preloadModule", metadata);
    /* TODO: Does it make sense to preload a module in esbuild? */
    return undefined;
  },

  /*
   * Called to synchronously obtain the actual module export (component or function).
   * This is the final step — the returned value is what React will render or invoke.
   *
   * Looks up modules from two global manifest maps populated by the esbuild build plugin:
   * - `window.__client_manifest_map` — maps client component IDs to their React components
   * - `window.__server_functions_manifest_map` — maps server function IDs to their callable functions
   *
   * @param metadata - The resolved reference with { type, id } from resolve*Reference
   * @returns The actual React component or server function
   * @throws If the module is not found in the manifest
   */
  requireModule(metadata) {
    const getModule = (type, id) => {
      switch (type) {
        case "ServerFunction":
          const fn = window.__server_functions_manifest_map[id];

          return fn;
        case "ClientComponent":
          const component = window.__client_manifest_map[id];

          return component
      }
    }

    const module = getModule(metadata.type, metadata.id);
    if (!module) {
      throw new Error(`Could not find module of type ${metadata.type} with id: ${metadata.id}`);
    }

    return module
  },
};

/*
 * The assembled config object passed to `ReactClientFlight($$$config)`.
 *
 * Combines all three config groups plus renderer metadata. The Flight client
 * destructures this to extract each function/value at module initialization time.
 *
 * TODO: Can we use the real thing, instead of mocks/vendored code here?
 */
const ReactServerDOMEsbuildConfig = {
  ...ReactFlightClientStreamConfigWeb,
  ...ReactClientConsoleConfigBrowser,
  ...ReactFlightClientConfigBundlerEsbuild,

  /* Reported to React DevTools via `__REACT_DEVTOOLS_GLOBAL_HOOK__` for identification. */
  rendererVersion: "19.1.0",

  /* Reported to React DevTools via `__REACT_DEVTOOLS_GLOBAL_HOOK__` for identification. */
  rendererPackageName: "react-server-dom-esbuild",

  /*
   * Indicates this Flight client is used with SSR. Currently extracted from the config
   * but NOT read by the `react-client/flight` internals — it has no runtime effect.
   * May be a forward-looking property for future React versions.
   */
  usedWithSSR: true,
};

/*
 * Initialize the Flight client with our esbuild-specific config.
 * This returns an object with the core Flight protocol functions.
 */
const {
  /* Creates a new Flight response object that accumulates streamed RSC data. */
  createResponse,
  /* Creates a reference to a server function that can be called from the client. */
  createServerReference: createServerReferenceImpl,
  /* Serializes a value (e.g., server action arguments) into a format suitable for sending to the server. */
  processReply,
  /* Returns the root promise of a Flight response — resolves to the React element tree. */
  getRoot,
  /* Reports a top-level error to all pending chunks in the response. */
  reportGlobalError,
  /* Processes a binary chunk from the ReadableStream into the Flight response. */
  processBinaryChunk,
  /* Creates a stream state object used to track binary chunk processing. */
  createStreamState,
  /* Signals that the stream is complete and no more chunks will arrive. */
  close,
} = ReactClientFlight(ReactServerDOMEsbuildConfig);

/*
 * Reads from a ReadableStream and feeds binary chunks into the Flight response.
 * Continues reading until the stream is done, then closes the response.
 */
function startReadingFromStream(response, stream) {
  const streamState = createStreamState();
  const reader = stream.getReader();
  function progress({
    done,
    value,
  }) {
    if (done) {
      close(response);
      return;
    }
    const buffer = value;
    processBinaryChunk(response, streamState, buffer);
    return reader.read().then(progress).catch(error);
  }
  function error(e) {
    reportGlobalError(response, e);
  }
  reader.read().then(progress).catch(error);
}

/*
 * Wraps `callServer` to provide a helpful error if no callback was registered.
 * The returned function is passed as the `callServer` parameter to `createResponse`.
 */
function callCurrentServerCallback(callServer) {
  return function (id, args) {
    if (!callServer) {
      throw new Error(
        "No server callback has been registered. Call setServerCallback to register one."
      );
    }
    return callServer(id, args);
  };
}

/*
 * Public API: Creates a Flight response from a ReadableStream.
 * Returns a thenable that resolves to the deserialized React element tree.
 *
 * @param stream - A ReadableStream containing the RSC payload
 * @param options - Optional config: { callServer, temporaryReferences }
 */
export function createFromReadableStream(stream, options) {
  const response = createResponseFromOptions(options);
  startReadingFromStream(response, stream);
  return getRoot(response);
}

/*
 * Internal helper to create a Flight response object from user-provided options.
 *
 * Maps the public API options to the internal `createResponse` parameters.
 *
 * Parameters to `createResponse`:
 *   1. bundlerConfig — null: client references are pre-resolved at build time by esbuild
 *   2. serverReferenceConfig — {}: truthy but empty, forces the `resolveServerReference` code path
 *      (when null/falsy, server refs fall back to `createBoundServerReference` using only `callServer`)
 *   3. moduleLoading — null: no dynamic module loading config needed (scripts are pre-loaded)
 *   4. callServer — callback invoked when a server action is called from the client
 *   5. encodeFormAction — undefined: no custom form action encoding (uses default)
 *   6. nonce — undefined: no CSP nonce needed for script injection
 *   7. temporaryReferences — allows objects to be passed by reference between server/client
 *   8. findSourceMapURL — undefined: no source map resolution (DEV only)
 *   9. replayConsoleLogs — false: server console log replay is disabled
 *  10. environmentName — undefined: no custom environment badge name (DEV only, defaults to "Server")
 */
function createResponseFromOptions(options) {
  let response = createResponse(
    null, // bundlerConfig
    {}, // serverReferenceConfig, this is the manifest that can contain configs related to server functions. It requires it to not be null, to run resolveServerReference
    null, // moduleLoading
    callCurrentServerCallback(options ? options.callServer : undefined),
    undefined, // encodeFormAction
    undefined, // nonce
    options && options.temporaryReferences
      ? options.temporaryReferences
      : undefined,
    undefined, // TODO: findSourceMapUrl
    false /* __DEV__ ? (options ? options.replayConsoleLogs !== false : true) */,
    undefined /* __DEV__ && options && options.environmentName
      ? options.environmentName
      : undefined */
  );

  return response;
}

/*
 * Public API: Creates a Flight response from a fetch() promise.
 * Waits for the fetch to resolve, then reads the response body as a stream.
 *
 * @param promise - A Promise<Response> (e.g., from `fetch("/rsc")`)
 * @param options - Optional config: { callServer, temporaryReferences }
 */
export function createFromFetch(promise, options) {
  const response = createResponseFromOptions(options);
  promise.then(
    function (r) {
      startReadingFromStream(response, r.body);
    },
    function (e) {
      reportGlobalError(response, e);
    }
  );
  return getRoot(response);
}

/*
 * Public API: Re-export of `createServerReference` from the Flight client.
 * Creates a callable reference to a server function identified by its ID.
 */
export const createServerReference = createServerReferenceImpl;

/*
 * Public API: Serializes a value into a format the server can decode.
 * Used to encode arguments when calling server actions.
 *
 * @param value - The value to serialize (can include React elements, FormData, etc.)
 * @param options.temporaryReferences - Optional map for temporary references
 * @param options.signal - Optional AbortSignal to cancel the encoding
 * @returns A Promise that resolves to the serialized form (string or FormData)
 */
export const encodeReply = (
  value,
  options = { temporaryReferences: undefined, signal: undefined }
) => {
  return new Promise((resolve, reject) => {
    const abort = processReply(
      value,
      "",
      options && options.temporaryReferences
        ? options.temporaryReferences
        : undefined,
      resolve,
      reject
    );
    if (options && options.signal) {
      const signal = options.signal;
      if (signal.aborted) {
        abort(signal.reason);
      } else {
        const listener = () => {
          abort(signal.reason);
          signal.removeEventListener("abort", listener);
        };
        signal.addEventListener("abort", listener);
      }
    }
  });
};
