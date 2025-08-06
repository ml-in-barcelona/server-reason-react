type arg;
type callServer = (string, list(arg)) => Js.Promise.t(React.element);

type options = {callServer};

[@mel.module
  "../../../packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js"
]
external createFromReadableStreamImpl:
  (Webapi.ReadableStream.t, ~options: options=?, unit) =>
  Js.Promise.t(React.element) =
  "createFromReadableStream";

[@mel.module
  "../../../packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js"
]
external createFromFetchImpl:
  (Js.Promise.t(Fetch.response), ~options: options=?, unit) => React.element =
  "createFromFetch";

[@mel.module
  "../../../packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js"
]
external createServerReferenceImpl:
  (
    string, // ServerReferenceId
    callServer,
    // EncodeFormActionCallback (optional) (We're not using this right now)
    option('encodeFormActionCallback),
    // FindSourceMapURLCallback (optional, DEV-only) (We're not using this right now)
    option('findSourceMapURLCallback),
    // functionName (optional)
    option(string)
  ) =>
  // actionCallback is a function that takes N arguments and returns a promise
  // As we don't have control over the number of arguments, we need to pass it as 'actionCallback
  'action =
  "createServerReference";

[@mel.module
  "../../../packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js"
]
external encodeReply: list('arg) => Js.Promise.t(string) = "encodeReply";

/* let callServerRef: ref(option(callServer('arg, 'result))) = ref(None); */
let callServerRef: ref(option(callServer)) = ref(None);
let setCallServer = callServer => {
  callServerRef := Some(callServer);
};
let getCallServer = () => {
  callServerRef^;
};

let createFromReadableStream =
    (~callServer=?, stream): Js.Promise.t(React.element) => {
  switch (callServer) {
  | Some(callServer) =>
    setCallServer(callServer);
    createFromReadableStreamImpl(
      stream,
      ~options={callServer: callServer},
      (),
    );
  | None => createFromReadableStreamImpl(stream, ())
  };
};

let createFromFetch = (~callServer=?, promise) => {
  switch (callServer) {
  | Some(callServer) =>
    setCallServer(callServer);
    createFromFetchImpl(promise, ~options={callServer: callServer}, ());
  | None => createFromFetchImpl(promise, ())
  };
};

let createServerReference = serverReferenceId => {
  let callServer =
    switch (getCallServer()) {
    | Some(callServer) => callServer
    | None =>
      raise(
        Invalid_argument(
          "No callServer has been set, you are trying to create a server function without passing callServer to createFromFetch or createFromReadableStream",
        ),
      )
    };
  createServerReferenceImpl(serverReferenceId, callServer, None, None, None);
};
