type callServerCallback('a, 'b) = (string, 'a) => Js.Promise.t('b);
type options('a, 'b) = {callServer: callServerCallback('a, 'b)};
/* TODO: Move this bindings into reason-react */
/* Before it was:
      [@mel.module "react-server-dom-webpack/client"]
       external createFromReadableStream:
         Webapi.ReadableStream.t => Js.Promise.t('a) =
         "createFromReadableStream";

      But in the react code it does not strict requires to be Js.Promise.t(React.element), but a generic type.1
      And server actions can also use it, so I changed it to return React.element
   */
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

type encodeFormAction = {
  name: option(string),
  value: option(string),
  encType: option(string),
  method: option(string),
  target: option(string),
  body: option(array(string)),
};

[@mel.module "react-server-dom-webpack/client"]
external createServerReferenceImpl:
  (
    string, // ServerReferenceId
    callServerCallback('a, 'b), // CallServerCallback
    option(('a, 'b) => encodeFormAction), // EncodeFormActionCallback (optional)
    option('e => string), // FindSourceMapURLCallback (optional, DEV-only)
    option(string)
  ) => // functionName (optional)
  'f =
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
