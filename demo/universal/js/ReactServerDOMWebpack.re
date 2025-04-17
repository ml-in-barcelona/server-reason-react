/* TODO: Move this bindings into reason-react */

type callServer('arg, 'result) =
  (string, list('arg)) => Js.Promise.t('result);

type options('arg, 'result) = {callServer: callServer('arg, 'result)};

type action('arg, 'result) = 'arg => Js.Promise.t('result);

[@mel.module "react-server-dom-webpack/client"]
external createFromReadableStreamImpl:
  (Webapi.ReadableStream.t, ~options: options('arg, 'result)=?, unit) =>
  Js.Promise.t('result) =
  "createFromReadableStream";

[@mel.module "react-server-dom-webpack/client"]
external createFromFetchImpl:
  (Js.Promise.t(Fetch.response), ~options: options('arg, 'result)=?, unit) =>
  React.element =
  "createFromFetch";

[@mel.module "react-server-dom-webpack/client"]
external createServerReferenceImpl:
  (
    string, // ServerReferenceId
    // CallServerCallback
    callServer('arg, 'result),
    // EncodeFormActionCallback (optional) (We're not using this right now)
    option('encodeFormActionCallback),
    // FindSourceMapURLCallback (optional, DEV-only) (We're not using this right now)
    option('findSourceMapURLCallback),
    // functionName (optional)
    option(string)
  ) =>
  action('arg, 'result) =
  "createServerReference";

[@mel.module "react-server-dom-webpack/client"]
external encodeReply: list('arg) => Js.Promise.t(string) = "encodeReply";

let callServer = (path, args) => {
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
