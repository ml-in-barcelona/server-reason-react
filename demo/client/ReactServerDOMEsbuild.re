[@mel.module "./../../../ReactServerDOMEsbuild.js"]
external createFromReadableStream:
  Webapi.ReadableStream.t => Js.Promise.t(React.element) =
  "createFromReadableStream";

[@mel.module "./../../../ReactServerDOMEsbuild.js"]
external createFromFetch: Js.Promise.t(Fetch.response) => React.element =
  "createFromFetch";
