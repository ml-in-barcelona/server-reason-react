import ReactClientFlight from "@pedrobslisboa/react-client/flight";

const isDebug = false;

const debug = (...args) => {
  if (isDebug && process.env.NODE_ENV === "development") {
    console.log(...args);
  }
};

const ReactFlightClientStreamConfigWeb = {
  createStringDecoder() {
    return new TextDecoder();
  },

  readPartialStringChunk(decoder, buffer) {
    return decoder.decode(buffer, { stream: true });
  },

  readFinalStringChunk(decoder, buffer) {
    return decoder.decode(buffer);
  },
};

const badgeFormat = "%c%s%c ";

const badgeStyle =
  "background: #e6e6e6;" +
  "background: light-dark(rgba(0,0,0,0.1), rgba(255,255,255,0.25));" +
  "color: #000000;" +
  "color: light-dark(#000000, #ffffff);" +
  "border-radius: 2px";

const resetStyle = "";
const pad = " ";

const bind = Function.prototype.bind;

const ReactClientConsoleConfigBrowser = {
  bindToConsole(methodName, args, badgeName) {
    let offset = 0;
    switch (methodName) {
      case "dir":
      case "dirxml":
      case "groupEnd":
      case "table": {
        return bind.apply(console[methodName], [console].concat(args));
      }
      case "assert": {
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

    newArgs.unshift(console);

    return bind.apply(console[methodName], newArgs);
  },
};

const ID = 0;
const NAME = 1;
const BUNDLES = 2;

const ReactFlightClientConfigBundlerEsbuild = {
  prepareDestinationForModule(moduleLoading, nonce, metadata) {
    debug("prepareDestinationForModule", moduleLoading, nonce, metadata);
    return;
  },

  resolveClientReference(bundlerConfig, metadata) {
    debug("resolveClientReference", bundlerConfig, metadata);
    return {
      type: "ClientComponent",
      id: metadata[ID],
      name: metadata[NAME],
      bundles: metadata[BUNDLES],
    };
  },

  resolveServerReference(bundlerConfig, ref) {
    debug("resolveServerReference", bundlerConfig, ref);

    return {
      type: "ServerFunction",
      id: ref,
    };
  },

  preloadModule(metadata) {
    debug("preloadModule", metadata);
    if (metadata.type !== "ClientComponent") {
      return undefined;
    }
    const entry = window.__client_manifest_map[metadata.id];
    if (!entry || entry.status === "fulfilled") {
      return undefined;
    }
    if (!entry.promise) {
      entry.promise = entry.load().then(
        (value) => {
          entry.status = "fulfilled";
          entry.value = value;
        },
        (error) => {
          entry.status = "rejected";
          entry.reason = error;
          throw error;
        },
      );
    }
    return entry.promise;
  },

  requireModule(metadata) {
    const getModule = (type, id) => {
      switch (type) {
        case "ServerFunction":
          return window.__server_functions_manifest_map[id];
        case "ClientComponent": {
          const entry = window.__client_manifest_map[id];
          if (!entry) {
            return undefined;
          }
          if (entry.status === "rejected") {
            throw entry.reason;
          }
          if (entry.status !== "fulfilled") {
            throw new Error(`Client component module "${id}" was required before it finished loading.`);
          }
          return entry.value;
        }
      }
    }

    const module = getModule(metadata.type, metadata.id);
    if (!module) {
      throw new Error(`Could not find module of type ${metadata.type} with id: ${metadata.id}`);
    }

    return module
  },
};

const ReactServerDOMEsbuildConfig = {
  ...ReactFlightClientStreamConfigWeb,
  ...ReactClientConsoleConfigBrowser,
  ...ReactFlightClientConfigBundlerEsbuild,

  rendererVersion: "19.1.0",

  rendererPackageName: "react-server-dom-esbuild",

  usedWithSSR: true,
};

const {
  createResponse,
  createServerReference: createServerReferenceImpl,
  processReply,
  getRoot,
  reportGlobalError,
  processBinaryChunk,
  createStreamState,
  close,
} = ReactClientFlight(ReactServerDOMEsbuildConfig);

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

function chainableRoot(chunk) {
  const originalThen = chunk.then.bind(chunk);
  chunk.then = function (onFulfilled, onRejected) {
    return new Promise(originalThen).then(onFulfilled, onRejected);
  };
  return chunk;
}

/*
 * Public API: Creates a Flight response from a ReadableStream.
 * Returns a chainable promise (see chainableRoot) that resolves to the
 * deserialized React element tree.
 *
 * @param stream - A ReadableStream containing the RSC payload
 * @param options - Optional config: { callServer, temporaryReferences }
 */
export function createFromReadableStream(stream, options) {
  const response = createResponseFromOptions(options);
  startReadingFromStream(response, stream);
  return chainableRoot(getRoot(response));
}

function createResponseFromOptions(options) {
  let response = createResponse(
    null,
    {},
    null,
    callCurrentServerCallback(options ? options.callServer : undefined),
    undefined,
    undefined,
    options && options.temporaryReferences
      ? options.temporaryReferences
      : undefined,
    undefined,
    false,
    undefined
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
  return chainableRoot(getRoot(response));
}

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
