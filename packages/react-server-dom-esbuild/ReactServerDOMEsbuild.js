/*
 * This file is a bundler integration between react (react-client/flight), esbuild and server-reason-react.
 *
 * Similar resources:
 * - **react-server-dom-webpack**: https://github.com/facebook/react/blob/5c56b873efb300b4d1afc4ba6f16acf17e4e5800/packages/react-server-dom-webpack/src/ReactFlightWebpackPlugin.js#L156-L194
 * - **react-server-dom-parcel**: https://github.com/facebook/react/pull/31725
*/

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
    /* TODO: Does it make sense to preload a module in esbuild? */
    return undefined;
  },

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
    {}, // serverFunctionsConfig, this is the manifest that can contain configs related to server functions. It requires it to not be null, to run resolveServerReference
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
