module ReadableStream = Webapi.ReadableStream;

external readable_stream: ReadableStream.t =
  "window.srr_stream.readable_stream";

let document: option(Webapi.Dom.Element.t) = [%mel.raw "window.document"];

let initialRSCModel =
  ReactServerDOMEsbuild.createFromReadableStream(readable_stream);

module ClientApp = {
  module DOM = Webapi.Dom;
  module Location = DOM.Location;
  module History = DOM.History;
  [@react.component]
  let make = () => {
    let initialElement = React.Experimental.usePromise(initialRSCModel);

    initialElement;
  };
};

switch (document) {
| Some(element) =>
  React.startTransition(() => {
    let _ = ReactDOM.Client.hydrateRoot(element, <ClientApp />);
    ();
  })
| None => Js.log("Root element not found")
};
