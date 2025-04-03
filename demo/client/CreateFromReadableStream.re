module App = {
  [@react.component]
  let make = (~promise) => {
    React.Experimental.use(promise);
  };
};

external readable_stream: Webapi.ReadableStream.t =
  "window.srr_stream.readable_stream";

[@mel.module "react"]
external startTransition: (unit => unit) => unit = "startTransition";

try({
  let promise =
    ReactServerDOMWebpack.createFromReadableStream(
      readable_stream,
      ~options={callServer: ReactServerDOMWebpack.callServer},
      (),
    );
  let body =
    Webapi.Dom.document
    ->Webapi.Dom.Document.asHtmlDocument
    ->Option.bind(Webapi.Dom.HtmlDocument.body);

  switch (body) {
  | Some(elem) =>
    startTransition(() => {
      let app = <App promise />;
      let _ = ReactDOM.Client.hydrateRoot(elem, app);
      ();
    })
  | None => Js.log("No root element found")
  };
}) {
| exn =>
  switch (Js.Exn.asJsExn(exn)) {
  | Some(error) =>
    Js.log2("Error type:", Js.Exn.name(error));
    Js.log2("Stack:", Js.Exn.stack(error));
    Js.log2("Full error:", error);
  | None =>
    Js.log("No JavaScript exception, got:");
    Js.log(exn);
  }
};
