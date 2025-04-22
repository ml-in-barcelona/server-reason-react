import ReactClientFlight from "@pedrobslisboa/react-client/flight";

const debug = (...args) => {
  if (process.env.NODE_ENV === "development") {
    console.log(...args);
  }
};

const ReactFlightClientStreamConfigWeb = {
  decoderOptions: { stream: true },
  createStringDecoder() {
    return new TextDecoder();
  },

  readPartialStringChunk(decoder, buffer) {
    return decoder.decode(buffer, decoderOptions);
  },

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

const ReactClientConsoleConfigBrowser = {
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
    // Reference is already resolved during the build
    return {
      id: metadata[ID],
      name: metadata[NAME],
      bundles: metadata[BUNDLES],
    };
  },

  resolveServerReference(bundlerConfig, ref) {
    debug("resolveServerReference", ref);
    const idx = ref.lastIndexOf("#");
    const id = ref.slice(0, idx);
    const name = ref.slice(idx + 1);
    const bundles = bundlerConfig[id];
    if (!bundles) {
      throw new Error("Invalid server action: " + ref);
    }
    return {
      id,
      name,
      bundles,
    };
  },

  preloadModule(metadata) {
    debug("preloadModule", metadata);
    /* TODO: Does it make sense to preload a module in esbuild? */
    return undefined;
  },

  requireModule(metadata) {
    const component = window.__client_manifest_map[metadata.id];
    if (!component) {
      /* TODO: use reportGlobalError? */
      throw new Error(
        `Could not find client component with id: ${metadata.id}`
      );
    }
    return component;
  },
};

/* TODO: Can we use the real thing, instead of mocks/vendored code here? */
const ReactServerDOMEsbuildConfig = {
  ...ReactFlightClientStreamConfigWeb,
  ...ReactClientConsoleConfigBrowser,
  ...ReactFlightClientConfigBundlerEsbuild,
  rendererVersion: "19.0.0",
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
  close,
} = ReactClientFlight(ReactServerDOMEsbuildConfig);

function startReadingFromStream(response, stream) {
  const reader = stream.getReader();
  function progress({ done, value }) {
    if (done) {
      close(response);
      return;
    }
    const buffer = value;
    processBinaryChunk(response, buffer);
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
        "No server callback has been registered. Call setServerCallback to register one."
      );
    }
    return callServer(id, args);
  };
}

export function createFromReadableStream(stream, options) {
  const response = createResponseFromOptions(options);
  startReadingFromStream(response, stream);
  return getRoot(response);
}

function createResponseFromOptions(options) {
  let response = createResponse(
    null, // bundlerConfig
    null, // serverReferenceConfig
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
  let fromJSON = response._fromJSON;
  let chunks = response._chunks;

  // Little hack to make the Server Function on client aligned to the server-reason-react contract
  /*
  {
    call: (...args) =>  action(...args)
    id: string
  }
  */
  response._fromJSON = (key, value) => {
    let modelParsed = fromJSON(key, value);
    // If the value is a reference_id prefixed by $F, it's a Server Function
    if (typeof value === "string" && value.startsWith("$F")) {
      let actionDetails = chunks.get(parseInt(value.substring(2)));
      modelParsed.call = modelParsed;
      modelParsed.id = actionDetails.id;
    }
    return modelParsed;
  };

  return response;
}

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

export const createServerReference = createServerReferenceImpl;

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
