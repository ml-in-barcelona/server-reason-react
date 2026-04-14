/* The raw arguments React passes to callServer — a JS array of the server function's arguments. */
type serverFunctionArgs;

type callServer = (string, serverFunctionArgs) => Js.Promise.t(React.element);

type temporaryReferences;

type options = {
  callServer,
  temporaryReferences: option(temporaryReferences),
};

type encodeReplyOptions = {
  temporaryReferences: option(temporaryReferences),
  signal: option(Fetch.AbortSignal.t),
};

[@mel.module "./ReactServerDOMEsbuild.js"]
external createFromReadableStreamImpl:
  (Webapi.ReadableStream.t, ~options: options=?, unit) => Js.Promise.t('a) =
  "createFromReadableStream";

[@mel.module "./ReactServerDOMEsbuild.js"]
external createFromFetchImpl:
  (Js.Promise.t(Fetch.response), ~options: options=?, unit) =>
  Js.Promise.t('a) =
  "createFromFetch";

[@mel.module "./ReactServerDOMEsbuild.js"]
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

[@mel.module "./ReactServerDOMEsbuild.js"]
external encodeReply: 'a => Js.Promise.t(Fetch.BodyInit.t) = "encodeReply";

[@mel.module "./ReactServerDOMEsbuild.js"]
external encodeReplyWithOptions:
  ('a, encodeReplyOptions) => Js.Promise.t(Fetch.BodyInit.t) =
  "encodeReply";

let callServerRef: ref(option(callServer)) = ref(None);
let setCallServer = callServer => {
  callServerRef := Some(callServer);
};
let getCallServer = () => {
  callServerRef^;
};

let createFromReadableStream =
    (~callServer=?, ~temporaryReferences=?, stream): Js.Promise.t('a) => {
  switch (callServer, temporaryReferences) {
  | (Some(callServer), temporaryReferences) =>
    setCallServer(callServer);
    createFromReadableStreamImpl(
      stream,
      ~options={
        callServer,
        temporaryReferences,
      },
      (),
    );
  | (None, None) => createFromReadableStreamImpl(stream, ())
  | (None, Some(_)) =>
    raise(
      Invalid_argument(
        "temporaryReferences requires callServer to be set. Pass ~callServer along with ~temporaryReferences.",
      ),
    )
  };
};

let createFromFetch = (~callServer=?, ~temporaryReferences=?, promise) => {
  switch (callServer, temporaryReferences) {
  | (Some(callServer), temporaryReferences) =>
    setCallServer(callServer);
    createFromFetchImpl(
      promise,
      ~options={
        callServer,
        temporaryReferences,
      },
      (),
    );
  | (None, None) => createFromFetchImpl(promise, ())
  | (None, Some(_)) =>
    raise(
      Invalid_argument(
        "temporaryReferences requires callServer to be set. Pass ~callServer along with ~temporaryReferences.",
      ),
    )
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
