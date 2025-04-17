import ReactClientFlight from "@matthamlin/react-client/flight";
import { encodeReply as encodeReplyFromWebpack } from "react-server-dom-webpack/client";

const ReactFlightClientStreamConfigWeb = {
  createStringDecoder() {
    return new TextDecoder();
  },

  decoderOptions: { stream: true },

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
    return;
  },

  resolveClientReference(bundlerConfig, metadata) {
    // Reference is already resolved during the build.
    return {
      id: metadata[ID],
      name: metadata[NAME],
      bundles: metadata[BUNDLES],
    };
  },

  resolveServerReference(bundlerConfig, ref) {
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
    /* TODO: Does it make sense to preload a module in esbuild? */
    return undefined;
  },

  requireModule(metadata) {
    const component = window.__client_manifest_map[metadata.id];
    if (!component) {
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
  const response = createResponse(
    null, // bundlerConfig
    null, // serverReferenceConfig
    null, // moduleLoading
    callCurrentServerCallback(options ? options.callServer : null),
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
  startReadingFromStream(response, stream);
  return getRoot(response);
}

export const hydrateRoot = (container, initialChildren) => {
  console.log("hydrateRoot", container, initialChildren);
  // Delegate to react-dom
  import("react-dom/client").then(({ hydrateRoot }) => {
    hydrateRoot(container, initialChildren);
  });
};

async function parseRSCStream(stream) {
  console.log("parseRSCStream", stream);
  const chunks = [];
  const reader = stream.getReader();
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  const data = chunks
    .join("")
    .split("\n")
    .map((line) => JSON.parse(line));
  return data.map((item) => {
    if (item["$"] === "react.client.reference") {
      return resolveClientReference(item.id);
    }
    return item; // Server component placeholder
  });
}

export const createFromFetch = (fetch) => {
  console.log("createFromFetch", fetch);
  return fetch.then((res) => parseRSCStream(res.body));
};

async function resolveClientReference(id) {
  console.log("resolveClientReference", id);
  const component = window.__client_manifest_map[id];
  if (!component) {
    throw new Error(`Could not find client component with id: ${id}`);
  }
  return { __esModule: true, default: component };
}

export function createServerReference(id, callServer) {
  let action = function () {
    const args = Array.prototype.slice.call(arguments);
    return callServer(id, args);
  };
  return action;
}

/* TODO: In order to have full control, we need to ??? with ReactFlightReply */
export const encodeReply = encodeReplyFromWebpack;
