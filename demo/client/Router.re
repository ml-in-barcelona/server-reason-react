module ReadableStream = Webapi.ReadableStream;

external readable_stream: ReadableStream.t =
  "window.srr_stream.readable_stream";

let document: option(Webapi.Dom.Element.t) = [%mel.raw "window.document"];

let body =
  Webapi.Dom.document
  ->Webapi.Dom.Document.asHtmlDocument
  ->Option.bind(Webapi.Dom.HtmlDocument.body);

let initialRSCModel =
  ReactServerDOMEsbuild.createFromReadableStream(readable_stream);

module ClientApp = {
  [@react.component]
  let make = () => {
    let initialElement = React.Experimental.use(initialRSCModel);
    <Supersonic.Router> initialElement </Supersonic.Router>;
  };
};

switch (body) {
| Some(element) =>
  React.startTransition(() => {
    let _ = ReactDOM.Client.hydrateRoot(element, <ClientApp />);
    ();
  })
| None => Js.log("Root element not found")
};
