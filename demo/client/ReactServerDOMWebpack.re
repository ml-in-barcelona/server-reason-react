/* TODO: Move this bindings into reason-react */

[@mel.module "react-server-dom-webpack/client"]
external createFromReadableStream:
  Webapi.ReadableStream.t => Js.Promise.t(React.element) =
  "createFromReadableStream";

[@mel.module "react-server-dom-webpack/client"]
external createFromFetch: Js.Promise.t(Fetch.response) => React.element =
  "createFromFetch";
