module ReadableStream = Webapi.ReadableStream;

external readable_stream: ReadableStream.t =
  "window.srr_stream.readable_stream";

let document: option(Webapi.Dom.Element.t) = [%mel.raw "window.document"];

let callServer = (path: string, args) => {
  let headers =
    Fetch.HeadersInit.make({
      "Accept": "application/react.action",
      "ACTION_ID": path,
    });
  ReactServerDOMEsbuild.encodeReply(args)
  |> Js.Promise.then_(body => {
       let body = Fetch.BodyInit.make(body);
       Fetch.fetchWithInit(
         "/",
         Fetch.RequestInit.make(~method_=Fetch.Post, ~headers, ~body, ()),
       )
       |> Js.Promise.then_(result => {
            let body = Fetch.Response.body(result);
            ReactServerDOMEsbuild.createFromReadableStream(body);
          });
     });
};

let initialRSCModel =
  ReactServerDOMEsbuild.createFromReadableStream(
    ~callServer,
    readable_stream,
  );

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
