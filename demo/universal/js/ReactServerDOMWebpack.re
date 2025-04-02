/* TODO: Move this bindings into reason-react */
type callServerCallback('a, 'b) = (string, list('a)) => Js.Promise.t('b);
type options('a, 'b) = {callServer: callServerCallback('a, 'b)};
type actionCallback('a, 'b) = 'a => Js.Promise.t('b);
[@mel.module "react-server-dom-webpack/client"]
external createFromReadableStream:
  (Webapi.ReadableStream.t, ~options: options('a, 'b)=?, unit) =>
  Js.Promise.t('a) =
  "createFromReadableStream";

[@mel.module "react-server-dom-webpack/client"]
external createFromFetch:
  (Js.Promise.t(Fetch.response), ~options: options('a, 'b)=?, unit) =>
  React.element =
  "createFromFetch";

[@mel.module "react-server-dom-webpack/client"]
external createServerReferenceImpl:
  (
    string, // ServerReferenceId
    // CallServerCallback
    callServerCallback('a, 'b),
    // EncodeFormActionCallback (optional)
    option(('a, 'b) => 'c),
    // FindSourceMapURLCallback (optional, DEV-only)
    option('e => string),
    // functionName (optional)
    option(string)
  ) =>
  actionCallback('d, 'b) =
  "createServerReference";

[@mel.module "react-server-dom-webpack/client"]
external encodeReply: 'a => Js.Promise.t('b) = "encodeReply";

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
            createFromReadableStream(body, ());
          });
     });
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
