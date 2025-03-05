[@mel.module "react-server-dom-esbuild/client"]
external createFromReadableStream:
  Webapi.ReadableStream.t => Js.Promise.t(React.element) =
  "createFromReadableStream";

[@mel.module "react-server-dom-esbuild/client"]
external createFromFetch: Js.Promise.t(Fetch.response) => React.element =
  "createFromFetch";
