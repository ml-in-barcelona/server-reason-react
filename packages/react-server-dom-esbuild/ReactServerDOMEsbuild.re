type arg;
type callServer = (string, list(arg)) => Js.Promise.t(React.element);

type options = {callServer};

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
external encodeReply: list('arg) => Js.Promise.t(string) = "encodeReply";

/* let callServerRef: ref(option(callServer('arg, 'result))) = ref(None); */
let callServerRef: ref(option(callServer)) = ref(None);
let setCallServer = callServer => {
  callServerRef := Some(callServer);
};
let getCallServer = () => {
  callServerRef^;
};

/* react-client returns a ReactPromise: a thenable whose `then` registers
   callbacks but returns unit instead of a chained promise, so chaining
   Js.Promise.then_ on it would resolve undefined. Promise.resolve
   assimilates it into a spec-compliant promise, making the declared type
   true. */
[@mel.scope "Promise"]
external assimilate: Js.Promise.t('a) => Js.Promise.t('a) = "resolve";

let createFromReadableStream = (~callServer=?, stream): Js.Promise.t('a) =>
  assimilate(
    switch (callServer) {
    | Some(callServer) =>
      setCallServer(callServer);
      createFromReadableStreamImpl(
        stream,
        ~options={ callServer: callServer },
        (),
      );
    | None => createFromReadableStreamImpl(stream, ())
    },
  );

let createFromFetch = (~callServer=?, promise) =>
  assimilate(
    switch (callServer) {
    | Some(callServer) =>
      setCallServer(callServer);
      createFromFetchImpl(promise, ~options={ callServer: callServer }, ());
    | None => createFromFetchImpl(promise, ())
    },
  );

/* The flight payload kept as react-client's raw ReactPromise. React.use
   reads its status field synchronously, which hydration needs to match the
   server HTML in one pass; assimilating it into a real promise loses that
   fast path. The type is abstract so `use` is the only way to consume it:
   the thenable's unit-returning `then` makes promise chaining on it
   unrepresentable rather than silently broken. */
module ComponentPayload = {
  type t;

  [@mel.module "./ReactServerDOMEsbuild.js"]
  external ofReadableStreamImpl:
    (Webapi.ReadableStream.t, ~options: options=?, unit) => t =
    "createFromReadableStream";

  let ofReadableStream = (~callServer=?, stream): t =>
    switch (callServer) {
    | Some(callServer) =>
      setCallServer(callServer);
      ofReadableStreamImpl(stream, ~options={ callServer: callServer }, ());
    | None => ofReadableStreamImpl(stream, ())
    };

  [@mel.module "react"] external use: t => React.element = "use";
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
