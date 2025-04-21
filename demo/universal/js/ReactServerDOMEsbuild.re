type callServer('arg, 'result) =
  (string, list('arg)) => Js.Promise.t('result);

type options('arg, 'result) = {callServer: callServer('arg, 'result)};

[@mel.module "./ReactServerDOMEsbuild.js"]
external createFromReadableStreamImpl:
  (Webapi.ReadableStream.t, ~options: options('arg, 'result)=?, unit) =>
  Js.Promise.t('result) =
  "createFromReadableStream";

[@mel.module "./ReactServerDOMEsbuild.js"]
external createFromFetchImpl:
  (Js.Promise.t(Fetch.response), ~options: options('arg, 'result)=?, unit) =>
  React.element =
  "createFromFetch";

[@mel.module "./ReactServerDOMEsbuild.js"]
external createServerReferenceImpl:
  (
    string, // ServerReferenceId
    callServer('arg, 'result),
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

let callServer = (path: string, args) => {
  let headers =
    Fetch.HeadersInit.make({
      "Accept": "application/react.action",
      "ACTION_ID": path,
    });
  encodeReply(args)
  |> Js.Promise.then_(body => {
       let body = Fetch.BodyInit.make(body);
       Fetch.fetchWithInit(
         "/",
         Fetch.RequestInit.make(~method_=Fetch.Post, ~headers, ~body, ()),
       )
       |> Js.Promise.then_(result => {
            let body = Fetch.Response.body(result);
            createFromReadableStreamImpl(body, ());
          });
     });
};

let createFromReadableStream = stream => {
  createFromReadableStreamImpl(
    stream,
    ~options={callServer: callServer},
    (),
  );
};

let createFromFetch = promise => {
  createFromFetchImpl(promise, ~options={callServer: callServer}, ());
};

let createServerReference = (serverReferenceId, functionName) => {
  createServerReferenceImpl(
    serverReferenceId,
    callServer,
    None,
    None,
    functionName,
  );
};
