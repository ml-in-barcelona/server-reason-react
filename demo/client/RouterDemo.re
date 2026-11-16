module ReadableStream = Webapi.ReadableStream;

external readable_stream: ReadableStream.t =
  "window.srr_stream.readable_stream";

let document: option(Webapi.Dom.Element.t) = [%mel.raw "window.document"];
let ssr =
  switch (
    Webapi.Dom.Document.getElementById("ssr-query-param", Webapi.Dom.document)
  ) {
  | Some(_) => true
  | None => false
  };

let callServer = ReactServerDOMEsbuild.fetchCallServer();

let initialRSCModel =
  ReactServerDOMEsbuild.createFromReadableStream(
    ~callServer,
    readable_stream,
  );

module ClientApp = {
  [@react.component]
  let make = () => {
    let initialElement = React.Experimental.usePromise(initialRSCModel);
    initialElement;
  };
};

switch (document) {
| Some(element) =>
  React.startTransition(() => {
    if (ssr) {
      let _ = ReactDOM.Client.hydrateRoot(element, <ClientApp />);
      ();
    } else {
      let root = ReactDOM.Client.createRoot(element);
      ReactDOM.Client.render(root, <ClientApp />);
    };
    ();
  })
| None => Js.log("Root element not found")
};
